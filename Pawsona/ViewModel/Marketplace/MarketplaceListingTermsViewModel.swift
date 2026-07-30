import Foundation
import Observation

/// Editing the commercial terms of a listing that is already public: whether it
/// is a sale or a free adoption, and what it costs. Deliberately separate from
/// the puppy snapshot, which is owned by the private puppy profile and refreshed
/// from it rather than typed in here.
@Observable
final class MarketplaceListingTermsViewModel {
    var listingType: MarketplaceListingType
    var priceText: String
    var isSaving = false
    var errorMessage: String?

    private let listingID: String
    private let repository: any MarketplaceRepository

    init(listing: MarketplaceListing, repository: any MarketplaceRepository) {
        self.listingID = listing.id
        self.repository = repository
        self.listingType = listing.listingType
        // IDR carries no fraction digits, so the amount is a plain integer and
        // the field seeds from digits rather than a formatted currency string
        // the user would then have to fight to edit.
        self.priceText = listing.priceAmount.map(String.init) ?? ""
    }

    var canSave: Bool {
        listingType == .adoption || parsedPrice != nil
    }

    var formattedPricePreview: String? {
        guard listingType == .sale, let parsedPrice else { return nil }
        return Decimal(parsedPrice).formatted(
            .currency(code: "IDR")
                .locale(Locale(identifier: "id_ID"))
                .precision(.fractionLength(0))
        )
    }

    /// Returns the saved listing, or `nil` when the save failed and
    /// `errorMessage` describes why.
    func save() async -> MarketplaceListing? {
        guard canSave else {
            errorMessage = MarketplaceError.invalidSalePrice.localizedDescription
            return nil
        }
        guard !isSaving else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            return try await repository.updateListingTerms(
                id: listingID,
                listingType: listingType,
                priceAmount: listingType == .sale ? parsedPrice : nil
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? MarketplaceError.serviceUnavailable.localizedDescription
            return nil
        }
    }

    private var parsedPrice: Int64? {
        let digits = priceText.filter(\.isNumber)
        guard let amount = Int64(digits), amount > 0 else { return nil }
        return amount
    }
}
