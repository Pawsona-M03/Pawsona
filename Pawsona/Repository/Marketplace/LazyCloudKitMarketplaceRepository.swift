import Foundation

final class LazyCloudKitMarketplaceRepository: MarketplaceRepository {
    private lazy var repository = CloudKitMarketplaceRepository()

    func accountState() async -> MarketplaceAccountState {
        await repository.accountState()
    }

    func fetchListings(
        query: MarketplaceListingQuery,
        after token: MarketplacePageToken?
    ) async throws -> MarketplacePage {
        try await repository.fetchListings(query: query, after: token)
    }

    func fetchListing(id: String) async throws -> MarketplaceListing {
        try await repository.fetchListing(id: id)
    }

    func fetchListing(sourceDogID: String) async throws -> MarketplaceListing? {
        try await repository.fetchListing(sourceDogID: sourceDogID)
    }

    func publish(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        try await repository.publish(listing)
    }

    func updateListingFromDog(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        try await repository.updateListingFromDog(listing)
    }

    func updateListingTerms(
        id: String,
        listingType: MarketplaceListingType,
        priceAmount: Int64?
    ) async throws -> MarketplaceListing {
        try await repository.updateListingTerms(
            id: id,
            listingType: listingType,
            priceAmount: priceAmount
        )
    }

    func updateListingStatus(id: String, status: MarketplaceListingStatus) async throws {
        try await repository.updateListingStatus(id: id, status: status)
    }

    func deleteListing(id: String) async throws {
        try await repository.deleteListing(id: id)
    }

    func fetchSellerProfile(id: String) async throws -> SellerProfile {
        try await repository.fetchSellerProfile(id: id)
    }

    func fetchCurrentSellerProfile() async throws -> SellerProfile? {
        try await repository.fetchCurrentSellerProfile()
    }

    func saveSellerProfile(
        _ profile: SellerProfile,
        contact: SellerContact
    ) async throws -> SellerProfile {
        try await repository.saveSellerProfile(profile, contact: contact)
    }

    func fetchSellerContact(sellerProfileID: String) async throws -> SellerContact {
        try await repository.fetchSellerContact(sellerProfileID: sellerProfileID)
    }

    func isListingOwnedByCurrentUser(id: String) async throws -> Bool {
        try await repository.isListingOwnedByCurrentUser(id: id)
    }

    func reportListing(
        id: String,
        reason: MarketplaceReportReason,
        details: String?
    ) async throws {
        try await repository.reportListing(id: id, reason: reason, details: details)
    }
}
