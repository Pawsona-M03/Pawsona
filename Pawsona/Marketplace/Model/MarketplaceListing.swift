import Foundation

struct MarketplaceListing: Identifiable, Equatable, Hashable {
    var id: String
    var sourceDogID: String
    var sellerProfileID: String
    var sellerCreatorRecordName: String?
    var name: String
    var breed: String
    var dateOfBirth: Date?
    var sex: Sex?
    var weight: Double?
    var backgroundColor: ColorType
    var photoData: Data?
    var vaccinationSummary: MarketplaceVaccinationSummary
    var listingType: MarketplaceListingType
    var priceAmount: Int64?
    var currencyCode: String
    var region: String
    var status: MarketplaceListingStatus
    var createdAt: Date
    var updatedAt: Date

    var priceText: String {
        guard listingType == .sale, let priceAmount else {
            return "Free adoption"
        }

        return Decimal(priceAmount).formatted(
            .currency(code: currencyCode)
                .locale(Locale(identifier: "id_ID"))
                .precision(.fractionLength(0))
        )
    }

    var ageText: String {
        PuppyAgeText.value(from: dateOfBirth) ?? "Age not provided"
    }

    func validated() throws -> Self {
        switch listingType {
        case .sale:
            guard let priceAmount, priceAmount > 0 else {
                throw MarketplaceError.invalidSalePrice
            }
        case .adoption:
            guard priceAmount == nil else {
                throw MarketplaceError.adoptionCannotHavePrice
            }
        }

        return self
    }
}
