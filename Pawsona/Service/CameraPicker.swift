//
//  CameraPicker.swift
//  Pawsona
//
//  Created by Aloysia Jennifer on 20/07/26.
//
//  Minimal UIImagePickerController wrapper — SwiftUI still has no native camera view.

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Refreshed every update so the coordinator's dismiss action stays
        // current. It used to hold a snapshot of the whole view struct taken at
        // makeCoordinator() time, which meant a stale @Environment(\.dismiss) —
        // a well-known source of "dismiss does nothing".
        context.coordinator.update(image: $image, dismiss: dismiss)
    }

    func makeCoordinator() -> Coordinator { Coordinator(image: $image, dismiss: dismiss) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private var image: Binding<UIImage?>
        private var dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self.image = image
            self.dismiss = dismiss
        }

        func update(image: Binding<UIImage?>, dismiss: DismissAction) {
            self.image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            image.wrappedValue = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
