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

    /// Re-attaches photo bytes we already hold in memory. CloudKit hands a saved
    /// record back with its `CKAsset` pointing at the temporary file we uploaded
    /// from, which is deleted the moment the save returns — so the round-trip
    /// would otherwise report a photo we know we sent as missing.
    func withPhotoData(_ photoData: Data?) -> Self {
        guard let photoData else { return self }
        var copy = self
        copy.photoData = photoData
        return copy
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
