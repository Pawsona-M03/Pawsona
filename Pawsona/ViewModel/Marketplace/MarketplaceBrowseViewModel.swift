import Foundation
import Observation

@Observable
final class MarketplaceBrowseViewModel {
    var query = MarketplaceListingQuery()
    var isLoading = false
    var isLoadingNextPage = false
    var hasLoaded = false
    var errorMessage: String?

    private(set) var listings: [MarketplaceListing] = []
    private(set) var nextToken: MarketplacePageToken?

    private let repository: any MarketplaceRepository
    private let blockStore: any SellerBlocking

    init(
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking
    ) {
        self.repository = repository
        self.blockStore = blockStore
    }

    var visibleListings: [MarketplaceListing] {
        query.sorted(
            listings.filter { listing in
                query.matches(listing)
                    && !blockStore.isBlocked(listing.sellerProfileID)
            }
        )
    }

    var isOffline: Bool {
        errorMessage == MarketplaceError.networkUnavailable.localizedDescription
    }

    var breeds: [String] {
        Set(listings.map(\.breed).filter { !$0.isEmpty }).sorted()
    }

    var regions: [String] {
        Set(listings.map(\.region).filter { !$0.isEmpty }).sorted()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            var page = try await repository.fetchListings(query: query, after: nil)
            var loadedListings = page.listings

            // CloudKit has no localized substring predicate. For an active
            // name/breed search, walk the bounded cursor window and apply the
            // localized match to each page instead of searching only page one.
            while !query.searchText.isEmpty,
                  let token = page.nextToken,
                  loadedListings.count < 240 {
                page = try await repository.fetchListings(query: query, after: token)
                let loadedIDs = Set(loadedListings.map(\.id))
                loadedListings.append(
                    contentsOf: page.listings.filter { !loadedIDs.contains($0.id) }
                )
            }

            listings = loadedListings
            nextToken = page.nextToken
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func loadNextPage() async {
        guard let nextToken, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        errorMessage = nil
        defer { isLoadingNextPage = false }

        do {
            let page = try await repository.fetchListings(query: query, after: nextToken)
            let existingIDs = Set(listings.map(\.id))
            listings.append(contentsOf: page.listings.filter { !existingIDs.contains($0.id) })
            self.nextToken = page.nextToken
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func applyFilters(_ updatedQuery: MarketplaceListingQuery) async {
        query = updatedQuery
        await reload()
    }

    func refreshBlockedSellers() {
        listings = Array(listings)
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? MarketplaceError.serviceUnavailable.localizedDescription
    }
}
