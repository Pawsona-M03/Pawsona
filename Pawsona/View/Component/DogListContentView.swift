//
//  DogListContentView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftData
import SwiftUI

struct DogListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DogViewModel()
    @State private var dogPendingDeletion: Dog?

    let filteredDogs: [Dog]
    let searchText: String
    let columns: [GridItem]

    var body: some View {
        Group {
            if filteredDogs.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Dogs Yet",
                        systemImage: "pawprint",
                        description: Text("Add a dog to start tracking reminders and vaccines.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(filteredDogs, id: \.id) { dog in
                            DogGridItemView(dog: dog)
                                .contextMenu {
                                    Button("Duplicate", systemImage: "plus.square.on.square") {
                                        viewModel.duplicateDog(dog, in: modelContext)
                                    }

                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        dogPendingDeletion = dog
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .accessibilityElement(children: .contain)
                .accessibilityRotor("Dogs") {
                    ForEach(filteredDogs, id: \.id) { dog in
                        AccessibilityRotorEntry(dog.displayName, id: dog.id)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.appBackground).ignoresSafeArea())
        .deleteConfirmation(
            $dogPendingDeletion,
            title: "Delete Puppy?",
            message: { dog in
                """
                This deletes \(dog.displayName). Their vaccine records and \
                reminders stay, unassigned. You can't undo this.
                """
            },
            perform: { dog in
                viewModel.deleteDog(dog, in: modelContext)
            }
        )
        .alert("Something went wrong", isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    DogListContentView(
        filteredDogs: [Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green)],
        searchText: "",
        columns: [GridItem(.flexible()), GridItem(.flexible())]
    )
}
