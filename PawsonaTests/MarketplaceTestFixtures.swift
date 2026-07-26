import Foundation
@testable import Pawsona

enum MarketplaceTestFixtures {
    static func listing(
        id: String = "listing-1",
        sellerProfileID: String = "seller-1",
        name: String = "Berry",
        breed: String = "Labrador Retriever",
        listingType: MarketplaceListingType = .sale,
        priceAmount: Int64? = 2_500_000,
        status: MarketplaceListingStatus = .available,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> MarketplaceListing {
        MarketplaceListing(
            id: id,
            sourceDogID: "safe-source",
            sellerProfileID: sellerProfileID,
            sellerCreatorRecordName: "creator-1",
            name: name,
            breed: breed,
            dateOfBirth: Date(timeIntervalSince1970: 1_650_000_000),
            sex: .female,
            weight: 12.5,
            backgroundColor: .green,
            photoData: nil,
            vaccinationSummary: MarketplaceVaccinationSummary(
                vaccineNames: ["Rabies"],
                recordCount: 1
            ),
            listingType: listingType,
            priceAmount: listingType == .adoption ? nil : priceAmount,
            currencyCode: "IDR",
            region: "Jakarta",
            status: status,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    static func sellerProfile(
        id: String = "seller-1",
        complete: Bool = true
    ) -> SellerProfile {
        SellerProfile(
            id: id,
            creatorRecordName: "creator-1",
            displayName: "Nathan",
            region: "Jakarta",
            sellerType: .individual,
            joinedAt: Date(timeIntervalSince1970: 1_600_000_000),
            profileComplete: complete,
            rulesAcceptedAt: complete ? Date(timeIntervalSince1970: 1_600_000_000) : nil
        )
    }
}
