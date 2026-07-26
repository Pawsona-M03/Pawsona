import CloudKit
import Foundation

// MARK: - Seller profile & contact

extension CloudKitMarketplaceRepository {
    func fetchSellerProfile(id: String) async throws -> SellerProfile {
        let record = try await withRetry {
            try await self.database.record(for: CKRecord.ID(recordName: id))
        }
        return try MarketplaceCloudKitMapper.sellerProfile(from: record)
    }

    func fetchCurrentSellerProfile() async throws -> SellerProfile? {
        let userRecordID = try await authenticatedUserRecordID()
        let profileID = Self.sellerProfileID(for: userRecordID)
        do {
            return try await fetchSellerProfile(id: profileID)
        } catch MarketplaceError.notFound {
            return nil
        }
    }

    func saveSellerProfile(
        _ profile: SellerProfile,
        contact: SellerContact
    ) async throws -> SellerProfile {
        let normalizedNumber = try MarketplacePhoneNumber.normalize(contact.whatsAppNumber)
        let userRecordID = try await authenticatedUserRecordID()
        let profileID = Self.sellerProfileID(for: userRecordID)
        let profileRecordID = CKRecord.ID(recordName: profileID)
        var profileRecord: CKRecord
        do {
            profileRecord = try await withRetry {
                try await self.database.record(for: profileRecordID)
            }
            try authorize(profileRecord, userRecordID: userRecordID)
        } catch MarketplaceError.notFound {
            profileRecord = CKRecord(
                recordType: MarketplaceCloudKitSchema.RecordType.sellerProfile,
                recordID: profileRecordID
            )
        }

        var savedProfile = profile
        savedProfile.id = profileID
        savedProfile.creatorRecordName = userRecordID.recordName
        savedProfile.joinedAt =
            profileRecord[MarketplaceCloudKitSchema.SellerProfileField.joinedAt] as? Date
            ?? profile.joinedAt
        savedProfile.profileComplete = savedProfile.hasRequiredFields

        guard savedProfile.profileComplete else {
            throw MarketplaceError.incompleteSellerProfile
        }

        MarketplaceCloudKitMapper.apply(savedProfile, to: profileRecord)
        let contactRecordID = CKRecord.ID(recordName: Self.sellerContactID(for: profileID))
        var contactRecord: CKRecord
        do {
            contactRecord = try await withRetry {
                try await self.database.record(for: contactRecordID)
            }
            try authorize(contactRecord, userRecordID: userRecordID)
        } catch MarketplaceError.notFound {
            contactRecord = CKRecord(
                recordType: MarketplaceCloudKitSchema.RecordType.sellerContact,
                recordID: contactRecordID
            )
        }

        MarketplaceCloudKitMapper.apply(
            SellerContact(
                sellerProfileID: profileID,
                whatsAppNumber: normalizedNumber,
                preferredMethod: contact.preferredMethod
            ),
            to: contactRecord
        )

        let results = try await withRetry {
            try await self.database.modifyRecords(
                saving: [profileRecord, contactRecord],
                deleting: [],
                savePolicy: .ifServerRecordUnchanged,
                atomically: true
            )
        }
        guard let profileResult = results.saveResults[profileRecordID] else {
            throw MarketplaceError.serviceUnavailable
        }
        let savedProfileRecord = try record(from: profileResult)

        return try MarketplaceCloudKitMapper.sellerProfile(from: savedProfileRecord)
    }

    func fetchSellerContact(sellerProfileID: String) async throws -> SellerContact {
        guard await accountState() == .available else {
            throw MarketplaceError.authenticationRequired
        }
        let recordID = CKRecord.ID(recordName: Self.sellerContactID(for: sellerProfileID))
        let record = try await withRetry {
            try await self.database.record(for: recordID)
        }
        return try MarketplaceCloudKitMapper.sellerContact(from: record)
    }

    /// Deterministic, so ownership can be decided from a record's own fields
    /// without a round trip to fetch the signed-in seller's profile.
    static func sellerProfileID(for userRecordID: CKRecord.ID) -> String {
        "seller-\(userRecordID.recordName)"
    }

    private static func sellerContactID(for profileID: String) -> String {
        "contact-\(profileID)"
    }
}
