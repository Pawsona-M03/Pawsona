//
//  DogPhotoPickerButton.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 22/07/26.
//

import PhotosUI
import SwiftUI
import UIKit

/// The dog form's 160pt photo well: shows the current photo or the placeholder
/// tinted with the dog's colour, and swaps in whatever the user picks.
///
/// Loading lives here rather than in the form so the picker owns the one piece
/// of state — the `PhotosPickerItem` — that nothing else on that screen reads.
struct DogPhotoPickerButton: View {
    @Binding var photoData: Data?
    let backgroundColor: ColorType

    @State private var photoSelection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $photoSelection, matching: .images) {
            label
        }
        .accessibilityLabel(
            photoData == nil ? "Add dog photo" : "Change dog photo"
        )
        .accessibilityValue(
            photoData == nil ? "No photo selected" : "Photo selected"
        )
        .onChange(of: photoSelection) { _, newSelection in
            loadPhoto(from: newSelection)
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
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "pencil")
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(.primaryBrown), in: .circle)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
        }
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
                    AccessibilityNotification.Announcement(
                        "Unable to load dog photo"
                    ).post()
                    return
                }

                photoData = loadedPhotoData
                AccessibilityNotification.Announcement("Dog photo selected")
                    .post()
            } catch {
                AccessibilityNotification.Announcement(
                    "Unable to load dog photo"
                ).post()
            }
        }
    }
}

#Preview {
    @Previewable @State var photoData: Data?

    DogPhotoPickerButton(photoData: $photoData, backgroundColor: .green)
}
