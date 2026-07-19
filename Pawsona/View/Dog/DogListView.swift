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
    @State private var exportedPDFURL: URL?
    @State private var searchText = ""

    private var filteredDogs: [Dog] {
        guard !searchText.isEmpty else {
            return viewModel.dogs
        }

        return viewModel.dogs.filter { dog in
            dog.name?.localizedStandardContains(searchText) == true
            || dog.breed.localizedStandardContains(searchText) == true
        }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            DogListContentView(filteredDogs: filteredDogs, searchText: searchText, columns: columns)
                .navigationTitle("Puppy")
            .navigationDestination(for: UUID.self) { dogID in
                if let dog = viewModel.getDog(id: dogID, in: modelContext) {
                    DogDetailView(dog: dog)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .searchDictationBehavior(.inline(activation: .onSelect))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        SortOrderPicker(selection: $viewModel.sortOption)
                    }
                    .tint(Color(.black))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Dog", systemImage: "plus", action: showAddDogForm)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.brown))
                }
            }
            .sheet(isPresented: $isShowingAddDogForm) {
                DogFormView(onSave: createDog)
            }
            .task {
                viewModel.getDogLists(in: modelContext)
            }
            .task(id: viewModel.dogs.map(\.id)) {
                exportedPDFURL = viewModel.exportDogsToPDF()
            }
            .onChange(of: viewModel.sortOption) { _, _ in
                viewModel.getDogLists(in: modelContext)
            }
            .onOpenURL { url in
                viewModel.importDogData(from: url, in: modelContext)
            }
        }
    }

    private func showAddDogForm() {
        isShowingAddDogForm = true
    }

    private func createDog(_ profile: DogProfile) {
        viewModel.createDog(profile, in: modelContext)
    }

    private func deleteDogs(at offsets: IndexSet) {
        let idsToDelete = offsets.map { viewModel.dogs[$0].id }

        Task {
            for id in idsToDelete {
                viewModel.deleteDog(id: id, in: modelContext)
            }
        }
    }
}

private struct SampleDogsPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Dog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let sampleDogs = [
            Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green, dateOfBirth: .now),
            Dog(name: "Milo", breed: "Golden Retriever", backgroundColor: .orange, dateOfBirth: .now),
            Dog(name: "Coco", breed: "Poodle", backgroundColor: .pink, dateOfBirth: .now),
            Dog(name: "Rex", breed: "German Shepherd", backgroundColor: .blue, dateOfBirth: .now),
            Dog(name: "Luna", breed: "Beagle", backgroundColor: .purple, dateOfBirth: .now)
        ]

        for dog in sampleDogs {
            container.mainContext.insert(dog)
        }

        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

#Preview(traits: .modifier(SampleDogsPreviewModifier())) {
    DogListView()
}
