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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible())]
        } else {
            [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        NavigationStack {
            DogListContentView(filteredDogs: filteredDogs, searchText: searchText, columns: columns)
                .navigationTitle("Puppy")
            .navigationDestination(for: UUID.self) { dogID in
                if let dog = viewModel.getDog(id: dogID, in: modelContext) {
                    DogDetailView(dog: dog)
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search dogs by name or breed"
            )
            .searchDictationBehavior(.inline(activation: .onSelect))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        SortOrderPicker(selection: $viewModel.sortOption)
                    }
                    .accessibilityLabel("Sort dogs")
                    .accessibilityValue(viewModel.sortOption.title)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Dog", systemImage: "plus", action: showAddDogForm)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
                        .accessibilityLabel("Add dog")
                }
            }
            .sheet(isPresented: $isShowingAddDogForm) {
                DogFormView { draft in
                    viewModel.createDog(from: draft, in: modelContext)
                }
            }
            .task {
                viewModel.getDogLists(in: modelContext)
            }
            .task(id: viewModel.dogs.map(\.id)) {
                exportedPDFURL = viewModel.exportDogsToPDF()
            }
            .task(id: searchText) {
                await announceSearchResults()
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

    private func announceSearchResults() async {
        guard !searchText.isEmpty else {
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(500))
        } catch {
            return
        }

        let resultCount = filteredDogs.count
        let announcement = switch resultCount {
        case 0: "No dogs found"
        case 1: "1 dog found"
        default: "\(resultCount) dogs found"
        }

        AccessibilityNotification.Announcement(announcement).post()
    }
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
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

    return DogListView()
        .modelContainer(container)
}
