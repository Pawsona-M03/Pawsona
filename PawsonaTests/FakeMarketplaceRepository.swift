import Foundation
@testable import Pawsona

final class FakeMarketplaceRepository: MarketplaceRepository {
    var account = MarketplaceAccountState.available
    var listings: [MarketplaceListing] = []
    var profile: SellerProfile?
    var contact = SellerContact(
        sellerProfileID: "seller-1",
        whatsAppNumber: "+6281234567890",
        preferredMethod: .whatsApp
    )
    var isOwner = false
    var fetchError: Error?
    var publishError: Error?
    /// Hands out a cursor on the first fetch so paging paths become reachable.
    var nextTokenForFirstPage: MarketplacePageToken?
    /// Fails every fetch after the first, to exercise the "page one worked,
    /// something later did not" branch.
    var errorAfterFirstFetch: Error?
    private(set) var fetchCount = 0
    var statusUpdates: [(String, MarketplaceListingStatus)] = []
    var termsUpdates: [RecordedTermsUpdate] = []
    var submittedReports: [(String, MarketplaceReportReason, String?)] = []
    var deletedListingIDs: [String] = []

    func accountState() async -> MarketplaceAccountState {
        account
    }

    func fetchListings(
        query: MarketplaceListingQuery,
        after token: MarketplacePageToken?
    ) async throws -> MarketplacePage {
        fetchCount += 1
        if let fetchError {
            throw fetchError
        }
        if fetchCount > 1, let errorAfterFirstFetch {
            throw errorAfterFirstFetch
        }
        return MarketplacePage(
            listings: query.sorted(listings.filter(query.matches)),
            nextToken: token == nil ? nextTokenForFirstPage : nil
        )
    }

    func fetchListing(id: String) async throws -> MarketplaceListing {
        guard let listing = listings.first(where: { $0.id == id }) else {
            throw MarketplaceError.notFound
        }
        return listing
    }

    func fetchListing(sourceDogID: String) async throws -> MarketplaceListing? {
        listings.first(where: { $0.sourceDogID == sourceDogID })
    }

    func publish(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        if let publishError {
            throw publishError
        }
        listings.append(listing)
        return listing
    }

    func updateListingFromDog(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        if let index = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[index] = listing
        }
        return listing
    }

    func updateListingTerms(
        id: String,
        listingType: MarketplaceListingType,
        priceAmount: Int64?
    ) async throws -> MarketplaceListing {
        guard let index = listings.firstIndex(where: { $0.id == id }) else {
            throw MarketplaceError.notFound
        }
        termsUpdates.append(
            RecordedTermsUpdate(
                listingID: id,
                listingType: listingType,
                priceAmount: priceAmount
            )
        )
        listings[index].listingType = listingType
        listings[index].priceAmount = listingType == .adoption ? nil : priceAmount
        listings[index].updatedAt = .now
        return try listings[index].validated()
    }

    func updateListingStatus(id: String, status: MarketplaceListingStatus) async throws {
        statusUpdates.append((id, status))
        if let index = listings.firstIndex(where: { $0.id == id }) {
            listings[index].status = status
        }
    }

    func deleteListing(id: String) async throws {
        deletedListingIDs.append(id)
        listings.removeAll { $0.id == id }
    }

    func fetchSellerProfile(id: String) async throws -> SellerProfile {
        guard let profile, profile.id == id else {
            throw MarketplaceError.notFound
        }
        return profile
    }

    func fetchCurrentSellerProfile() async throws -> SellerProfile? {
        profile
    }

    func saveSellerProfile(
        _ profile: SellerProfile,
        contact: SellerContact
    ) async throws -> SellerProfile {
        var saved = profile
        saved.id = "seller-1"
        saved.profileComplete = saved.hasRequiredFields
        self.profile = saved
        self.contact = SellerContact(
            sellerProfileID: saved.id,
            whatsAppNumber: contact.whatsAppNumber,
            preferredMethod: contact.preferredMethod
        )
        return saved
    }

    func fetchSellerContact(sellerProfileID: String) async throws -> SellerContact {
        guard account == .available else {
            throw MarketplaceError.authenticationRequired
        }
        return contact
    }

    func isListingOwnedByCurrentUser(id: String) async throws -> Bool {
        isOwner
    }

    func reportListing(
        id: String,
        reason: MarketplaceReportReason,
        details: String?
    ) async throws {
        guard account == .available else {
            throw MarketplaceError.authenticationRequired
        }
        submittedReports.append((id, reason, details))
    }
}
