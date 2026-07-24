import Foundation
import Observation

@Observable
final class MarketplacePublishingViewModel {
    enum Step {
        case checkingAccount
        case requiresICloud(String)
        case sellerProfile
        case confirmation
        case published(MarketplaceListing)
    }

    var step: Step = .checkingAccount
    var displayName = ""
    var region = ""
    var sellerType = SellerType.individual
    var phoneNumber = ""
    var preferredContactMethod = PreferredContactMethod.whatsApp
    var acceptedMarketplaceRules = false
    var listingType = MarketplaceListingType.sale
    var priceText = ""
    var acceptedPublicSharing = false
    var acceptedContactSharing = false
    var isSaving = false
    var errorMessage: String?

    private(set) var sellerProfile: SellerProfile?

    private let repository: any MarketplaceRepository

    init(repository: any MarketplaceRepository) {
        self.repository = repository
    }

    var canSaveProfile: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && acceptedMarketplaceRules
    }

    var canPublish: Bool {
        acceptedPublicSharing
            && acceptedContactSharing
            && (listingType == .adoption || parsedPrice != nil)
    }

    func prepare() async {
        step = .checkingAccount
        errorMessage = nil
        let accountState = await repository.accountState()
        guard accountState == .available else {
            step = .requiresICloud(
                accountState.requiresSignInMessage
                    ?? MarketplaceError.authenticationRequired.localizedDescription
            )
            return
        }

        do {
            if let profile = try await repository.fetchCurrentSellerProfile(),
               profile.profileComplete {
                sellerProfile = profile
                step = .confirmation
            } else {
                step = .sellerProfile
            }
        } catch {
            errorMessage = readableMessage(for: error)
            step = .sellerProfile
        }
    }

    func saveSellerProfile() async {
        guard canSaveProfile else {
            errorMessage = MarketplaceError.incompleteSellerProfile.localizedDescription
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let normalizedNumber = try MarketplacePhoneNumber.normalize(phoneNumber)
            let profile = SellerProfile(
                id: "",
                creatorRecordName: nil,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                region: region.trimmingCharacters(in: .whitespacesAndNewlines),
                sellerType: sellerType,
                joinedAt: .now,
                profileComplete: true,
                rulesAcceptedAt: .now
            )
            sellerProfile = try await repository.saveSellerProfile(
                profile,
                contact: SellerContact(
                    sellerProfileID: "",
                    whatsAppNumber: normalizedNumber,
                    preferredMethod: preferredContactMethod
                )
            )
            step = .confirmation
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func publish(puppy: MarketplacePuppySnapshot) async {
        guard let sellerProfile, canPublish else {
            errorMessage = MarketplaceError.incompleteSellerProfile.localizedDescription
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let listing = try MarketplaceDogSnapshotMapper.listing(
                from: puppy,
                sellerProfile: sellerProfile,
                listingType: listingType,
                priceAmount: listingType == .sale ? parsedPrice : nil
            )
            let published = try await repository.publish(listing)
            step = .published(published)
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private var parsedPrice: Int64? {
        let digits = priceText.filter(\.isNumber)
        guard let amount = Int64(digits), amount > 0 else { return nil }
        return amount
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? MarketplaceError.serviceUnavailable.localizedDescription
    }
}
