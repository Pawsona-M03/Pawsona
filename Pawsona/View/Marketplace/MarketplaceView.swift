import SwiftUI

struct MarketplaceView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: MarketplaceBrowseViewModel
    @State private var isShowingFilters = false
    @State private var isShowingBlockedSellers = false

    private let repository: any MarketplaceRepository
    private let blockStore: any SellerBlocking

    init(
        repository: any MarketplaceRepository = LazyCloudKitMarketplaceRepository(),
        blockStore: any SellerBlocking = UserDefaultsSellerBlockStore()
    ) {
        self.repository = repository
        self.blockStore = blockStore
        _viewModel = State(
            initialValue: MarketplaceBrowseViewModel(
                repository: repository,
                blockStore: blockStore
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoading, !viewModel.hasLoaded {
                    ProgressView("Loading marketplace")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Loading marketplace listings")
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.listings.isEmpty {
                    ContentUnavailableView {
                        Label(
                            viewModel.isOffline ? "You're Offline" : "Marketplace Unavailable",
                            systemImage: viewModel.isOffline ? "wifi.slash" : "exclamationmark.triangle"
                        )
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await viewModel.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.visibleListings.isEmpty {
                    ContentUnavailableView {
                        Label(
                            viewModel.query.searchText.isEmpty
                                ? "No Listings Yet" : "No Listings Found",
                            systemImage: "pawprint"
                        )
                    } description: {
                        Text(
                            viewModel.query.hasFilters || !viewModel.query.searchText.isEmpty
                                ? "Try changing your search or filters."
                                : "Available puppies will appear here."
                        )
                    } actions: {
                        if viewModel.query.hasFilters {
                            Button("Clear Filters") {
                                var query = MarketplaceListingQuery()
                                query.searchText = viewModel.query.searchText
                                Task { await viewModel.applyFilters(query) }
                            }
                        }
                    }
                } else {
                    MarketplaceGridContentView(
                        listings: viewModel.visibleListings,
                        columns: columns,
                        isLoadingNextPage: viewModel.isLoadingNextPage,
                        hasNextPage: viewModel.nextToken != nil,
                        noticeMessage: viewModel.noticeMessage,
                        isOwnListing: viewModel.isOwnListing,
                        dismissNotice: { viewModel.noticeMessage = nil },
                        loadNextPage: {
                            Task { await viewModel.loadNextPage() }
                        }
                    )
                    .refreshable {
                        await viewModel.reload()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.appBackground).ignoresSafeArea())
            .navigationTitle("Marketplace")
            .navigationDestination(for: MarketplaceListing.self) { listing in
                MarketplaceDetailView(
                    listing: listing,
                    repository: repository,
                    blockStore: blockStore,
                    isKnownOwnListing: viewModel.isOwnListing(listing)
                )
            }
            .searchable(
                text: $viewModel.query.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by puppy name or breed"
            )
            .searchDictationBehavior(.inline(activation: .onSelect))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Picker("Sort listings", selection: $viewModel.query.sort) {
                            ForEach(MarketplaceSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .onChange(of: viewModel.query.sort) {
                            Task { await viewModel.reload() }
                        }
                    }
                    .tint(.primary)
                    .accessibilityValue(viewModel.query.sort.displayName)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Filters", systemImage: "line.3.horizontal.decrease") {
                        isShowingFilters = true
                    }
                    .tint(viewModel.query.hasFilters ? Color(.primaryBrown) : .primary)
                    .accessibilityValue(viewModel.query.hasFilters ? "Filters applied" : "No filters")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More", systemImage: "ellipsis.circle") {
                        Button("Blocked Sellers", systemImage: "person.crop.circle.badge.xmark") {
                            isShowingBlockedSellers = true
                        }
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isShowingFilters) {
                MarketplaceFilterView(
                    query: viewModel.query,
                    breeds: viewModel.breeds,
                    regions: viewModel.regions
                ) { query in
                    Task { await viewModel.applyFilters(query) }
                }
            }
            .sheet(isPresented: $isShowingBlockedSellers) {
                viewModel.refreshBlockedSellers()
            } content: {
                BlockedSellersView(repository: repository, blockStore: blockStore)
            }
            .task {
                await viewModel.loadCurrentSeller()
                if !viewModel.hasLoaded {
                    await viewModel.reload()
                }
            }
            .task(id: viewModel.query.searchText) {
                guard viewModel.hasLoaded else { return }
                do {
                    try await Task.sleep(for: .milliseconds(350))
                } catch {
                    return
                }
                await viewModel.reload()
            }
        }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

}
