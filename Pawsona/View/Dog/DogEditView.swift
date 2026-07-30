//
//  DogEditView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogEditView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DogViewModel()

    let dog: Dog

    /// Reports that the user confirmed deletion — it does not delete anything
    /// itself. The presenting screen owns the delete so it can tear itself down
    /// first; see `DogDetailView`.
    let onDelete: () -> Void

    var body: some View {
        DogFormView(
            title: "Edit Dog",
            saveTitle: "Save",
            draft: DogDraft(
                name: dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                breed: dog.breed,
                dateOfBirth: dog.dateOfBirth ?? .now,
                backgroundColor: dog.backgroundColor,
                weightKg: dog.weight,
                sex: dog.sex,
                photoData: dog.photoData
            ),
            onDelete: onDelete,
            onSave: editDog
        )
    }

    private func editDog(from draft: DogDraft) {
        viewModel.editDog(dog, from: draft, in: modelContext)
        AccessibilityNotification.Announcement("Dog updated").post()
    }
}

#Preview {
    DogEditView(
        dog: Dog(
            name: "Berry",
            breed: "Labrador Retriever",
            backgroundColor: .green,
            dateOfBirth: Date.now
        ),
        onDelete: {}
    )
    .modelContainer(for: Dog.self, inMemory: true)
}
