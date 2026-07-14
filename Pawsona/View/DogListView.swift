//
//  DogListView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DogViewModel()
    @State private var isShowingAddDogForm = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.dogs.isEmpty {
                    ContentUnavailableView(
                        "No Dogs Yet",
                        systemImage: "pawprint",
                        description: Text("Add a dog to start tracking reminders and vaccines.")
                    )
                } else {
                    ForEach(viewModel.dogs, id: \.id) { dog in
                        NavigationLink(value: dog.id) {
                            DogCardView(dog: dog)
                        }
                    }
                    .onDelete(perform: deleteDogs)
                }
            }
            .navigationTitle("Home")
        }
    }

    private func showAddDogForm() {
        isShowingAddDogForm = true
    }

    private func createDog(
        name: String,
        breed: String,
        dateOfBirth: Date,
        backgroundColor: ColorType
    ) {
        viewModel.createDog(
            name: name,
            breed: breed,
            dateOfBirth: dateOfBirth,
            backgroundColor: backgroundColor,
            in: modelContext
        )
    }

    private func deleteDogs(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteDog(id: viewModel.dogs[index].id, in: modelContext)
        }
    }
}

#Preview {
    DogListView()
        .modelContainer(for: Dog.self, inMemory: true)
}
