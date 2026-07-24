import CryptoKit
import Foundation

enum MarketplaceDogSnapshotMapper {
    static func safeSourceID(for dog: Dog) -> String {
        let source = Data("pawsona-marketplace-v1:\(dog.id.uuidString.lowercased())".utf8)
        return SHA256.hash(data: source).map { byte in
            let value = String(byte, radix: 16)
            return value.count == 1 ? "0\(value)" : value
        }.joined()
    }

    static func listing(
        from dog: Dog,
        sellerProfile: SellerProfile,
        listingType: MarketplaceListingType,
        priceAmount: Int64?,
        existingListing: MarketplaceListing? = nil,
        now: Date = .now
    ) throws -> MarketplaceListing {
        try listing(
            from: snapshot(from: dog),
            sellerProfile: sellerProfile,
            listingType: listingType,
            priceAmount: priceAmount,
            existingListing: existingListing,
            now: now
        )
    }

    static func snapshot(from dog: Dog) -> MarketplacePuppySnapshot {
        let vaccineNames = Set(
            (dog.vaccineRecords ?? []).flatMap { record in
                record.vaccines.map(\.displayName)
            }
        )
        .sorted()

        return MarketplacePuppySnapshot(
            sourceDogID: safeSourceID(for: dog),
            name: dog.displayName,
            breed: dog.breed,
            dateOfBirth: dog.dateOfBirth,
            sex: dog.sex,
            weight: dog.weight,
            backgroundColor: dog.backgroundColor,
            photoData: dog.photoData,
            vaccinationSummary: MarketplaceVaccinationSummary(
                vaccineNames: vaccineNames,
                recordCount: dog.vaccineRecords?.count ?? 0
            )
        )
    }

    static func listing(
        from snapshot: MarketplacePuppySnapshot,
        sellerProfile: SellerProfile,
        listingType: MarketplaceListingType,
        priceAmount: Int64?,
        existingListing: MarketplaceListing? = nil,
        now: Date = .now
    ) throws -> MarketplaceListing {
        let listing = MarketplaceListing(
            id: existingListing?.id ?? UUID().uuidString.lowercased(),
            sourceDogID: snapshot.sourceDogID,
            sellerProfileID: sellerProfile.id,
            sellerCreatorRecordName: sellerProfile.creatorRecordName,
            name: snapshot.name,
            breed: snapshot.breed,
            dateOfBirth: snapshot.dateOfBirth,
            sex: snapshot.sex,
            weight: snapshot.weight,
            backgroundColor: snapshot.backgroundColor,
            photoData: snapshot.photoData,
            vaccinationSummary: snapshot.vaccinationSummary,
            listingType: listingType,
            priceAmount: listingType == .adoption ? nil : priceAmount,
            currencyCode: "IDR",
            region: sellerProfile.region,
            status: existingListing?.status ?? .available,
            createdAt: existingListing?.createdAt ?? now,
            updatedAt: now
        )
        return try listing.validated()
    }
}
