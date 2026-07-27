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
    @State private var searchText = ""
    @State private var sortOption: DogSortOption = .dateAdded
    @State private var sortDirection: DogSortDirection = .descending

    private let marketplaceRepository: any MarketplaceRepository
    private let sellerBlockStore: any SellerBlocking

    init(
        marketplaceRepository: any MarketplaceRepository = LazyCloudKitMarketplaceRepository(),
        sellerBlockStore: any SellerBlocking = UserDefaultsSellerBlockStore()
    ) {
        self.marketplaceRepository = marketplaceRepository
        self.sellerBlockStore = sellerBlockStore
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
            // The sort lives in a child so `@Query` can be rebuilt with a new
            // sort descriptor when it changes — a Query's sort is fixed at init.
            SortedDogListView(
                sortOption: sortOption,
                sortDirection: sortDirection,
                searchText: searchText,
                columns: columns
            )
                .navigationTitle("Puppy")
                .navigationDestination(for: Dog.self) { dog in
                    DogDetailView(
                        dog: dog,
                        marketplaceRepository: marketplaceRepository,
                        sellerBlockStore: sellerBlockStore
                    )
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
                            SortOrderPicker(selection: $sortOption, direction: $sortDirection)
                        }
                        .tint(.primary)
                        .accessibilityLabel("Sort dogs")
                        .accessibilityValue(
                            "\(sortOption.title), \(sortOption.directionTitle(for: sortDirection))"
                        )
                        .onChange(of: sortOption) { _, newOption in
                            sortDirection = newOption.defaultDirection
                        }
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
                .alert("Something went wrong", isPresented: $viewModel.isShowingError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    private func showAddDogForm() {
        isShowingAddDogForm = true
    }
}

/// Owns the `@Query` for one sort order. `DogListView` swaps this view out when
/// the sort changes, which is what re-runs the query.
private struct SortedDogListView: View {
    @Query private var dogs: [Dog]

    let searchText: String
    let columns: [GridItem]

    init(sortOption: DogSortOption, sortDirection: DogSortDirection, searchText: String, columns: [GridItem]) {
        _dogs = Query(sort: [sortOption.sortDescriptor(direction: sortDirection)])
        self.searchText = searchText
        self.columns = columns
    }

    private var filteredDogs: [Dog] {
        guard !searchText.isEmpty else {
            return dogs
        }

        return dogs.filter { dog in
            dog.name?.localizedStandardContains(searchText) == true
                || dog.breed.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        DogListContentView(filteredDogs: filteredDogs, searchText: searchText, columns: columns)
            .task(id: searchText) {
                await announceSearchResults()
            }
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
        Dog(
            name: "Berry",
            breed: "Labrador Retriever",
            backgroundColor: .green,
            dateOfBirth: DateComponents(
                calendar: .current,
                year: 2000,
                month: 10,
                day: 19
            ).date ?? .now
        ),
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
