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

    var body: some View {
        DogFormView(
            title: "Edit Dog",
            profile: DogProfile(
                name: dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                breed: dog.breed,
                dateOfBirth: dog.dateOfBirth ?? .now,
                backgroundColor: dog.backgroundColor,
                photoData: dog.photoData
            ),
            onSave: editDog
        )
    }

    private func editDog(_ profile: DogProfile) {
        viewModel.editDog(dog, profile: profile, in: modelContext)
    }
}

#Preview {
    DogEditView(
        dog: Dog(
            name: "Berry",
            breed: "Labrador Retriever",
            backgroundColor: .green,
            dateOfBirth: Date.now
        )
    )
    .modelContainer(for: Dog.self, inMemory: true)
}
