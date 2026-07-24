import CloudKit
import Foundation

enum MarketplaceCloudKitMapper {
    static func apply(_ listing: MarketplaceListing, to record: CKRecord) {
        record[MarketplaceCloudKitSchema.ListingField.sourceDogID] = listing.sourceDogID
        record[MarketplaceCloudKitSchema.ListingField.sellerProfile] = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: listing.sellerProfileID),
            action: .none
        )
        record[MarketplaceCloudKitSchema.ListingField.name] = listing.name
        record[MarketplaceCloudKitSchema.ListingField.breed] = listing.breed
        record[MarketplaceCloudKitSchema.ListingField.dateOfBirth] = listing.dateOfBirth
        record[MarketplaceCloudKitSchema.ListingField.sex] = listing.sex?.rawValue
        record[MarketplaceCloudKitSchema.ListingField.weight] = listing.weight
        record[MarketplaceCloudKitSchema.ListingField.backgroundColor] = listing.backgroundColor.rawValue
        record[MarketplaceCloudKitSchema.ListingField.vaccinationNames] =
            listing.vaccinationSummary.vaccineNames
        record[MarketplaceCloudKitSchema.ListingField.vaccinationRecordCount] =
            listing.vaccinationSummary.recordCount
        record[MarketplaceCloudKitSchema.ListingField.listingType] = listing.listingType.rawValue
        record[MarketplaceCloudKitSchema.ListingField.priceAmount] = listing.priceAmount
        record[MarketplaceCloudKitSchema.ListingField.currencyCode] = listing.currencyCode
        record[MarketplaceCloudKitSchema.ListingField.region] = listing.region
        record[MarketplaceCloudKitSchema.ListingField.status] = listing.status.rawValue
        record[MarketplaceCloudKitSchema.ListingField.createdAt] = listing.createdAt
        record[MarketplaceCloudKitSchema.ListingField.updatedAt] = listing.updatedAt
    }

    static func listing(from record: CKRecord) throws -> MarketplaceListing {
        guard
            let sourceDogID = record[MarketplaceCloudKitSchema.ListingField.sourceDogID] as? String,
            let sellerReference =
                record[MarketplaceCloudKitSchema.ListingField.sellerProfile] as? CKRecord.Reference,
            let name = record[MarketplaceCloudKitSchema.ListingField.name] as? String,
            let breed = record[MarketplaceCloudKitSchema.ListingField.breed] as? String,
            let backgroundRaw =
                record[MarketplaceCloudKitSchema.ListingField.backgroundColor] as? String,
            let backgroundColor = ColorType(rawValue: backgroundRaw),
            let listingTypeRaw =
                record[MarketplaceCloudKitSchema.ListingField.listingType] as? String,
            let listingType = MarketplaceListingType(rawValue: listingTypeRaw),
            let currencyCode =
                record[MarketplaceCloudKitSchema.ListingField.currencyCode] as? String,
            let region = record[MarketplaceCloudKitSchema.ListingField.region] as? String,
            let statusRaw = record[MarketplaceCloudKitSchema.ListingField.status] as? String,
            let status = MarketplaceListingStatus(rawValue: statusRaw),
            let createdAt = record[MarketplaceCloudKitSchema.ListingField.createdAt] as? Date,
            let updatedAt = record[MarketplaceCloudKitSchema.ListingField.updatedAt] as? Date
        else {
            throw MarketplaceError.invalidRecord
        }

        let sex = (record[MarketplaceCloudKitSchema.ListingField.sex] as? String)
            .flatMap(Sex.init(rawValue:))
        let photoData = try photoData(
            from: record[MarketplaceCloudKitSchema.ListingField.photo] as? CKAsset
        )

        let listing = MarketplaceListing(
            id: record.recordID.recordName,
            sourceDogID: sourceDogID,
            sellerProfileID: sellerReference.recordID.recordName,
            sellerCreatorRecordName: record.creatorUserRecordID?.recordName,
            name: name,
            breed: breed,
            dateOfBirth: record[MarketplaceCloudKitSchema.ListingField.dateOfBirth] as? Date,
            sex: sex,
            weight: record[MarketplaceCloudKitSchema.ListingField.weight] as? Double,
            backgroundColor: backgroundColor,
            photoData: photoData,
            vaccinationSummary: MarketplaceVaccinationSummary(
                vaccineNames:
                    record[MarketplaceCloudKitSchema.ListingField.vaccinationNames]
                    as? [String] ?? [],
                recordCount:
                    record[MarketplaceCloudKitSchema.ListingField.vaccinationRecordCount]
                    as? Int ?? 0
            ),
            listingType: listingType,
            priceAmount:
                (record[MarketplaceCloudKitSchema.ListingField.priceAmount] as? NSNumber)?
                .int64Value,
            currencyCode: currencyCode,
            region: region,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        return try listing.validated()
    }

    static func apply(_ profile: SellerProfile, to record: CKRecord) {
        record[MarketplaceCloudKitSchema.SellerProfileField.displayName] = profile.displayName
        record[MarketplaceCloudKitSchema.SellerProfileField.region] = profile.region
        record[MarketplaceCloudKitSchema.SellerProfileField.sellerType] = profile.sellerType.rawValue
        record[MarketplaceCloudKitSchema.SellerProfileField.joinedAt] = profile.joinedAt
        record[MarketplaceCloudKitSchema.SellerProfileField.profileComplete] = profile.profileComplete
        record[MarketplaceCloudKitSchema.SellerProfileField.rulesAcceptedAt] =
            profile.rulesAcceptedAt
    }

    static func sellerProfile(from record: CKRecord) throws -> SellerProfile {
        guard
            let displayName =
                record[MarketplaceCloudKitSchema.SellerProfileField.displayName] as? String,
            let region = record[MarketplaceCloudKitSchema.SellerProfileField.region] as? String,
            let sellerTypeRaw =
                record[MarketplaceCloudKitSchema.SellerProfileField.sellerType] as? String,
            let sellerType = SellerType(rawValue: sellerTypeRaw),
            let joinedAt =
                record[MarketplaceCloudKitSchema.SellerProfileField.joinedAt] as? Date
        else {
            throw MarketplaceError.invalidRecord
        }

        return SellerProfile(
            id: record.recordID.recordName,
            creatorRecordName: record.creatorUserRecordID?.recordName,
            displayName: displayName,
            region: region,
            sellerType: sellerType,
            joinedAt: joinedAt,
            profileComplete:
                record[MarketplaceCloudKitSchema.SellerProfileField.profileComplete]
                as? Bool ?? false,
            rulesAcceptedAt:
                record[MarketplaceCloudKitSchema.SellerProfileField.rulesAcceptedAt] as? Date
        )
    }

    static func apply(_ contact: SellerContact, to record: CKRecord) {
        record[MarketplaceCloudKitSchema.SellerContactField.sellerProfile] = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: contact.sellerProfileID),
            action: .none
        )
        record[MarketplaceCloudKitSchema.SellerContactField.whatsAppNumber] =
            contact.whatsAppNumber
        record[MarketplaceCloudKitSchema.SellerContactField.preferredMethod] =
            contact.preferredMethod.rawValue
        record[MarketplaceCloudKitSchema.SellerContactField.updatedAt] = Date.now
    }

    static func sellerContact(from record: CKRecord) throws -> SellerContact {
        guard
            let sellerReference =
                record[MarketplaceCloudKitSchema.SellerContactField.sellerProfile]
                as? CKRecord.Reference,
            let number =
                record[MarketplaceCloudKitSchema.SellerContactField.whatsAppNumber] as? String,
            let methodRaw =
                record[MarketplaceCloudKitSchema.SellerContactField.preferredMethod] as? String,
            let method = PreferredContactMethod(rawValue: methodRaw)
        else {
            throw MarketplaceError.invalidRecord
        }

        return SellerContact(
            sellerProfileID: sellerReference.recordID.recordName,
            whatsAppNumber: number,
            preferredMethod: method
        )
    }

    private static func photoData(from asset: CKAsset?) throws -> Data? {
        guard let fileURL = asset?.fileURL else { return nil }
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw MarketplaceError.invalidRecord
        }
    }
}
