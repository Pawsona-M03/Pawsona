//
//  DogDetailView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogDetailView: View {
    let dog: Dog

    @State private var isShowingEditDogForm = false

    var body: some View {
        List {
            Section {
                DogCardView(dog: dog)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Profile") {
                LabeledContent("Name", value: displayName)
                LabeledContent("Breed", value: dog.breed.isEmpty ? "Not set" : dog.breed)
                LabeledContent("Birthday", value: dog.dateOfBirth.formatted(date: .long, time: .omitted))
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", systemImage: "pencil", action: showEditDogForm)
                    .accessibilityShowsLargeContentViewer()
            }
        }
        .sheet(isPresented: $isShowingEditDogForm) {
            DogEditView(dog: dog)
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private func showEditDogForm() {
        isShowingEditDogForm = true
    }
}

#Preview {
    NavigationStack {
        DogDetailView(
            dog: Dog(
                name: "Berry",
                breed: "Labrador Retriever",
                dateOfBirth: Date.now,
                backgroundColor: .green
            )
        )
    }
    .modelContainer(for: Dog.self, inMemory: true)
}
