import Foundation

protocol MarketplaceRepository {
    func accountState() async -> MarketplaceAccountState
    func fetchListings(
        query: MarketplaceListingQuery,
        after token: MarketplacePageToken?
    ) async throws -> MarketplacePage
    func fetchListing(id: String) async throws -> MarketplaceListing
    func fetchListing(sourceDogID: String) async throws -> MarketplaceListing?
    func publish(_ listing: MarketplaceListing) async throws -> MarketplaceListing
    func updateListingFromDog(_ listing: MarketplaceListing) async throws -> MarketplaceListing
    func updateListingStatus(id: String, status: MarketplaceListingStatus) async throws
    func deleteListing(id: String) async throws
    func fetchSellerProfile(id: String) async throws -> SellerProfile
    func fetchCurrentSellerProfile() async throws -> SellerProfile?
    func saveSellerProfile(
        _ profile: SellerProfile,
        contact: SellerContact
    ) async throws -> SellerProfile
    func fetchSellerContact(sellerProfileID: String) async throws -> SellerContact
    func isListingOwnedByCurrentUser(id: String) async throws -> Bool
    func reportListing(
        id: String,
        reason: MarketplaceReportReason,
        details: String?
    ) async throws
}
