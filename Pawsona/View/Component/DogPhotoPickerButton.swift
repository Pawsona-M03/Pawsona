//
//  DogPhotoPickerButton.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 22/07/26.
//

import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import UIKit
import Vision

/// The dog form's 160pt photo well: shows the current photo or the placeholder
/// tinted with the dog's colour, and swaps in a photo from the camera or library.
///
/// Loading lives here rather than in the form so the picker owns the photo-source
/// presentation and selection state that nothing else on that screen reads.
struct DogPhotoPickerButton: View {
    @Binding var photoData: Data?
    let backgroundColor: ColorType

    @State private var photoSelection: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var subjectCutout: CIImage?
    @State private var isProcessingPhoto = false
    @State private var processingError: String?
    @State private var isShowingSourceOptions = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false

    private static let ciContext = CIContext()

    var body: some View {
        Button {
            isShowingSourceOptions = true
        } label: {
            label
        }
        .buttonStyle(.plain)
        .disabled(isProcessingPhoto)
        .accessibilityLabel(
            photoData == nil ? "Add dog photo" : "Change dog photo"
        )
        .accessibilityValue(
            isProcessingPhoto
                ? "Finding the dog in the photo"
                : photoData == nil ? "No photo selected" : "Photo selected"
        )
        .confirmationDialog(
            "Choose Photo Source",
            isPresented: $isShowingSourceOptions,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    isShowingCamera = true
                }
            }

            Button("Photo Library") {
                isShowingPhotoLibrary = true
            }
        }
        .photosPicker(
            isPresented: $isShowingPhotoLibrary,
            selection: $photoSelection,
            matching: .images
        )
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: photoSelection) { _, newSelection in
            loadPhoto(from: newSelection)
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else {
                return
            }

            processPhoto(newImage)
            capturedImage = nil
        }
        .onChange(of: backgroundColor) {
            renderCachedCutout()
        }
        .onChange(of: subjectCutout) {
            renderCachedCutout()
        }
        .alert(
            "Unable to Process Photo",
            isPresented: Binding(
                get: { processingError != nil },
                set: { isPresented in
                    if !isPresented {
                        processingError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(processingError ?? "")
        }
    }

    @ViewBuilder
    private var label: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
            } else {
                Rectangle()
                    .fill(backgroundColor.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .overlay(alignment: .bottom) {
                        Image(.dogPlaceholder)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                    }
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            if isProcessingPhoto {
                ZStack {
                    Color.black.opacity(0.35)

                    ProgressView("Finding dog…")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
            }
        }
//        .overlay(alignment: .bottomTrailing) {
//            Image(systemName: "pencil")
//                .font(.body.bold())
//                .foregroundStyle(.white)
//                .frame(width: 44, height: 44)
//                .background(Color(.primaryBrown), in: .circle)
//                .padding(.bottom, 6)
//                .accessibilityHidden(true)
//        }
    }

    private func loadPhoto(from selection: PhotosPickerItem?) {
        guard let selection else {
            return
        }

        Task {
            do {
                guard
                    let loadedPhotoData = try await selection.loadTransferable(
                        type: Data.self
                    )
                else {
                    showProcessingError("The selected photo could not be loaded.")
                    return
                }

                guard let image = UIImage(data: loadedPhotoData) else {
                    showProcessingError("The selected photo could not be read.")
                    return
                }

                processPhoto(image)
                photoSelection = nil
            } catch {
                showProcessingError(error.localizedDescription)
            }
        }
    }

    /// Center-crop the image, isolate its foreground subject with Vision, and
    /// cache the transparent cutout so changing the card colour can re-render it.
    private func processPhoto(_ image: UIImage) {
        processingError = nil
        subjectCutout = nil
        isProcessingPhoto = true
        AccessibilityNotification.Announcement("Finding dog in photo").post()

        guard let cgImage = image.fixedOrientation().cgImage else {
            showProcessingError("The selected photo could not be read.")
            return
        }

        Task.detached(priority: .userInitiated) {
            do {
                let squareImage = CIImage(cgImage: cgImage)
                    .centerCroppedToSquare()
                let handler = VNImageRequestHandler(ciImage: squareImage)
                let request = VNGenerateForegroundInstanceMaskRequest()

                try handler.perform([request])

                guard let observation = request.results?.first else {
                    throw DogPhotoProcessingError.subjectNotFound
                }

                let maskBuffer = try observation.generateScaledMaskForImage(
                    forInstances: observation.allInstances,
                    from: handler
                )
                let blendFilter = CIFilter.blendWithMask()
                blendFilter.inputImage = squareImage
                blendFilter.backgroundImage = CIImage(color: .clear)
                    .cropped(to: squareImage.extent)
                blendFilter.maskImage = CIImage(cvPixelBuffer: maskBuffer)

                guard let cutout = blendFilter.outputImage else {
                    throw DogPhotoProcessingError.renderFailed
                }

                await MainActor.run {
                    subjectCutout = cutout
                    isProcessingPhoto = false
                    AccessibilityNotification.Announcement(
                        "Dog photo selected"
                    ).post()
                }
            } catch {
                await MainActor.run {
                    showProcessingError(error.localizedDescription)
                }
            }
        }
    }

    /// Re-composite the cached cutout whenever it or the card colour changes.
    ///
    /// Both callers are `onChange` actions, which SwiftUI rebuilds on every body
    /// pass, so `backgroundColor` here is always the colour currently selected.
    /// Rendering straight from `processPhoto` instead would use the colour
    /// captured when the photo was picked, which goes stale if the user changes
    /// the card colour while the subject is still being extracted.
    private func renderCachedCutout() {
        guard let subjectCutout else {
            return
        }

        renderPhoto(from: subjectCutout)
    }

    /// Composite the transparent subject over the currently selected card colour.
    private func renderPhoto(from cutout: CIImage) {
        let background = CIImage(
            color: CIColor(color: UIColor(backgroundColor.color))
        )
        .cropped(to: cutout.extent)
        let composited = cutout.composited(over: background)

        guard
            let renderedCGImage = Self.ciContext.createCGImage(
                composited,
                from: composited.extent
            ),
            let renderedData = UIImage(cgImage: renderedCGImage)
                .jpegData(compressionQuality: 0.9)
        else {
            showProcessingError(
                DogPhotoProcessingError.renderFailed.localizedDescription
            )
            return
        }

        photoData = renderedData
    }

    private func showProcessingError(_ message: String) {
        isProcessingPhoto = false
        processingError = message
        AccessibilityNotification.Announcement(
            "Unable to process dog photo"
        ).post()
    }
}

private enum DogPhotoProcessingError: LocalizedError {
    case subjectNotFound
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .subjectNotFound:
            "No clear subject was found. Try a photo where your dog is fully visible."
        case .renderFailed:
            "The processed photo could not be created. Please try another photo."
        }
    }
}

private extension CIImage {
    nonisolated func centerCroppedToSquare() -> CIImage {
        let side = min(extent.width, extent.height)
        let cropRect = CGRect(
            x: extent.midX - side / 2,
            y: extent.midY - side / 2,
            width: side,
            height: side
        )

        return cropped(to: cropRect)
            .transformed(
                by: .init(
                    translationX: -cropRect.minX,
                    y: -cropRect.minY
                )
            )
    }
}

private extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    @Previewable @State var photoData: Data?

    DogPhotoPickerButton(photoData: $photoData, backgroundColor: .green)
}
