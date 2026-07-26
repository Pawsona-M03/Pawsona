import Foundation
import Observation

@Observable
final class MarketplaceDetailViewModel {
    private(set) var listing: MarketplaceListing
    private(set) var sellerProfile: SellerProfile?
    private(set) var sellerContact: SellerContact?
    private(set) var isOwner = false
    var isLoading = false
    var isPerformingAction = false
    var errorMessage: String?
    var confirmationMessage: String?

    private let repository: any MarketplaceRepository
    private let blockStore: any SellerBlocking

    init(
        listing: MarketplaceListing,
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking,
        isKnownOwnListing: Bool = false
    ) {
        self.listing = listing
        self.repository = repository
        self.blockStore = blockStore
        // Browse already resolved ownership against the signed-in seller
        // profile. Seeding it here means the owner never sees a frame of the
        // buyer's UI — Contact Seller, Report, Block — on their own listing.
        isOwner = isKnownOwnListing
    }

    var isSellerBlocked: Bool {
        blockStore.isBlocked(listing.sellerProfileID)
    }

    /// Reporting or blocking yourself is never a real intent, and self-blocking
    /// silently hid the user's own puppy from Marketplace with no way to
    /// discover why.
    var canReportOrBlock: Bool { !isOwner }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let profile = repository.fetchSellerProfile(id: listing.sellerProfileID)
            sellerProfile = try await profile
            let currentProfile = (try? await repository.fetchCurrentSellerProfile()) ?? nil
            if let currentProfile, currentProfile.id == listing.sellerProfileID {
                isOwner = true
            } else if let confirmed = try? await repository
                .isListingOwnedByCurrentUser(id: listing.id) {
                isOwner = confirmed
            }
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func revealContact() async {
        isPerformingAction = true
        errorMessage = nil
        defer { isPerformingAction = false }

        guard await repository.accountState() == .available else {
            errorMessage = MarketplaceError.authenticationRequired.localizedDescription
            return
        }

        do {
            sellerContact = try await repository.fetchSellerContact(
                sellerProfileID: listing.sellerProfileID
            )
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func updateStatus(_ status: MarketplaceListingStatus) async {
        await performAction {
            try await self.repository.updateListingStatus(id: self.listing.id, status: status)
            self.listing.status = status
            self.listing.updatedAt = .now
            self.confirmationMessage = "Listing marked \(status.displayName.lowercased())."
        }
    }

    func updateFromPuppy(_ snapshot: MarketplacePuppySnapshot) async {
        guard let sellerProfile else {
            errorMessage = MarketplaceError.incompleteSellerProfile.localizedDescription
            return
        }

        await performAction {
            let listingSnapshot = try MarketplaceDogSnapshotMapper.listing(
                from: snapshot,
                sellerProfile: sellerProfile,
                listingType: self.listing.listingType,
                priceAmount: self.listing.priceAmount,
                existingListing: self.listing
            )
            self.listing = try await self.repository.updateListingFromDog(listingSnapshot)
            self.confirmationMessage = "Listing updated from the puppy profile."
        }
    }

    func replaceListing(
        _ updatedListing: MarketplaceListing,
        message: String = "Listing updated from the puppy profile."
    ) {
        listing = updatedListing
        confirmationMessage = message
    }

    func showMessage(_ message: String) {
        errorMessage = message
    }

    func removeListing() async -> Bool {
        var removed = false
        await performAction {
            try await self.repository.deleteListing(id: self.listing.id)
            removed = true
        }
        return removed
    }

    func submitReport(reason: MarketplaceReportReason, details: String?) async -> Bool {
        var submitted = false
        await performAction {
            try await self.repository.reportListing(
                id: self.listing.id,
                reason: reason,
                details: details
            )
            self.confirmationMessage = "Report submitted. Thank you for helping keep Pawsona safe."
            submitted = true
        }
        return submitted
    }

    func blockSeller() {
        guard !isOwner else {
            errorMessage = "You can't block yourself. This is your own listing."
            return
        }
        blockStore.block(listing.sellerProfileID)
        confirmationMessage = "Seller blocked. Their listings will no longer appear."
    }

    func unblockSeller() {
        blockStore.unblock(listing.sellerProfileID)
        confirmationMessage = "Seller unblocked."
    }

    private func performAction(_ action: () async throws -> Void) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        errorMessage = nil
        defer { isPerformingAction = false }

        do {
            try await action()
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? MarketplaceError.serviceUnavailable.localizedDescription
    }
}
