import Foundation
import Observation

@Observable
final class MarketplaceBrowseViewModel {
    var query = MarketplaceListingQuery()
    var isLoading = false
    var isLoadingNextPage = false
    var hasLoaded = false

    /// Blocking failure: we have nothing to show, so the screen becomes the error.
    var errorMessage: String?

    /// Non-blocking failure: listings are on screen and usable, something
    /// secondary (a continuation page, a "load more") failed. Surfaced inline
    /// rather than as a modal — interrupting a working grid with an alert the
    /// user can only dismiss is noise, not information.
    var noticeMessage: String?

    private(set) var listings: [MarketplaceListing] = []
    private(set) var nextToken: MarketplacePageToken?
    private(set) var currentSeller: SellerProfile?

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
                query.matches(listing) && !isHiddenByBlock(listing)
            }
        )
    }

    /// Whether this listing was posted by the signed-in user.
    ///
    /// Matched *only* on the seller profile the listing was published under.
    /// `sellerCreatorRecordName` looks like a tempting second signal, but the
    /// public database reports `creatorUserRecordID` inconsistently, and this
    /// check must fail closed: a false "this is yours" hides Report and Block
    /// on a stranger's listing, which is a safety tool the user may need. Being
    /// wrong the other way costs nothing but a redundant button.
    func isOwnListing(_ listing: MarketplaceListing) -> Bool {
        guard let currentSeller else { return false }
        return listing.sellerProfileID == currentSeller.id
    }

    /// Your own listings are never hidden by a block. Blocking is a tool for
    /// getting away from other people, and a self-block used to silently erase
    /// your puppy from the grid with no way to tell why.
    private func isHiddenByBlock(_ listing: MarketplaceListing) -> Bool {
        !isOwnListing(listing) && blockStore.isBlocked(listing.sellerProfileID)
    }

    func loadCurrentSeller() async {
        guard currentSeller == nil else { return }
        currentSeller = (try? await repository.fetchCurrentSellerProfile()) ?? nil
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
        noticeMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            var page = try await repository.fetchListings(query: query, after: nil)
            var loadedListings = page.listings

            do {
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
            } catch {
                // The first page already succeeded. Failing to widen the search
                // window costs us later matches, not the ones in hand — so keep
                // them and say so quietly.
                noticeMessage = readableMessage(for: error)
            }

            listings = loadedListings
            nextToken = page.nextToken
        } catch {
            // Only take over the screen when there is nothing else to show. A
            // failed pull-to-refresh over a populated grid leaves results that
            // are stale, not wrong — replacing them with a full-screen error
            // (or worse, an alert) throws away something the user can still use.
            if listings.isEmpty {
                errorMessage = readableMessage(for: error)
            } else {
                noticeMessage = readableMessage(for: error)
            }
        }
    }

    func loadNextPage() async {
        guard let nextToken, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        noticeMessage = nil
        defer { isLoadingNextPage = false }

        do {
            let page = try await repository.fetchListings(query: query, after: nextToken)
            let existingIDs = Set(listings.map(\.id))
            listings.append(contentsOf: page.listings.filter { !existingIDs.contains($0.id) })
            self.nextToken = page.nextToken
        } catch {
            // Paging is additive. Whatever is already on screen stays valid.
            noticeMessage = readableMessage(for: error)
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
