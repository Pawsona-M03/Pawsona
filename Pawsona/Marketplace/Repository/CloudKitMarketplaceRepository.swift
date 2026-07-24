import CloudKit
import Foundation

final class CloudKitMarketplaceRepository: MarketplaceRepository {
    private let container: CKContainer
    private let database: CKDatabase
    private let pageSize: Int
    private var cursors: [String: CKQueryOperation.Cursor] = [:]

    init(container: CKContainer = .default(), pageSize: Int = 24) {
        self.container = container
        self.database = container.publicCloudDatabase
        self.pageSize = pageSize
    }

    func accountState() async -> MarketplaceAccountState {
        do {
            return switch try await container.accountStatus() {
            case .available: .available
            case .noAccount: .noAccount
            case .restricted: .restricted
            case .couldNotDetermine: .couldNotDetermine
            case .temporarilyUnavailable: .temporarilyUnavailable
            @unknown default: .couldNotDetermine
            }
        } catch {
            return .temporarilyUnavailable
        }
    }

    func fetchListings(
        query: MarketplaceListingQuery,
        after token: MarketplacePageToken?
    ) async throws -> MarketplacePage {
        let response = try await withRetry {
            if let token {
                guard let cursor = self.cursors[token.rawValue] else {
                    throw MarketplaceError.notFound
                }
                return try await self.database.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: nil,
                    resultsLimit: self.pageSize
                )
            }

            let cloudQuery = CKQuery(
                recordType: MarketplaceCloudKitSchema.RecordType.listing,
                predicate: self.predicate(for: query)
            )
            cloudQuery.sortDescriptors = self.sortDescriptors(for: query.sort)
            return try await self.database.records(
                matching: cloudQuery,
                desiredKeys: nil,
                resultsLimit: self.pageSize
            )
        }

        let listings = try response.matchResults.compactMap { _, result in
            let record = try record(from: result)
            return try MarketplaceCloudKitMapper.listing(from: record)
        }

        let nextToken = response.queryCursor.map { cursor in
            let token = MarketplacePageToken(rawValue: UUID().uuidString)
            cursors[token.rawValue] = cursor
            return token
        }

        return MarketplacePage(
            listings: query.sorted(listings.filter(query.matches)),
            nextToken: nextToken
        )
    }

    func fetchListing(id: String) async throws -> MarketplaceListing {
        let record = try await record(id: id)
        return try MarketplaceCloudKitMapper.listing(from: record)
    }

    func fetchListing(sourceDogID: String) async throws -> MarketplaceListing? {
        let userRecordID = try await authenticatedUserRecordID()
        let cloudQuery = CKQuery(
            recordType: MarketplaceCloudKitSchema.RecordType.listing,
            predicate: NSPredicate(
                format: "%K == %@",
                MarketplaceCloudKitSchema.ListingField.sourceDogID,
                sourceDogID
            )
        )
        let response = try await withRetry {
            try await self.database.records(
                matching: cloudQuery,
                desiredKeys: nil,
                resultsLimit: 100
            )
        }
        for (_, result) in response.matchResults {
            let record = try record(from: result)
            if record.creatorUserRecordID == userRecordID {
                return try MarketplaceCloudKitMapper.listing(from: record)
            }
        }
        return nil
    }

    func publish(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        let validatedListing = try listing.validated()
        let currentProfile = try await fetchCurrentSellerProfile()
        guard let currentProfile,
              currentProfile.profileComplete,
              currentProfile.id == validatedListing.sellerProfileID else {
            throw MarketplaceError.incompleteSellerProfile
        }

        let record = CKRecord(
            recordType: MarketplaceCloudKitSchema.RecordType.listing,
            recordID: CKRecord.ID(recordName: validatedListing.id)
        )
        MarketplaceCloudKitMapper.apply(validatedListing, to: record)
        let saved = try await save(record, photoData: validatedListing.photoData)
        return try MarketplaceCloudKitMapper.listing(from: saved)
    }

    func updateListingFromDog(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        _ = try listing.validated()
        let record = try await ownedRecord(id: listing.id)
        let existing = try MarketplaceCloudKitMapper.listing(from: record)
        guard existing.sourceDogID == listing.sourceDogID else {
            throw MarketplaceError.notAuthorized
        }

        var updated = existing
        updated.name = listing.name
        updated.breed = listing.breed
        updated.dateOfBirth = listing.dateOfBirth
        updated.sex = listing.sex
        updated.weight = listing.weight
        updated.backgroundColor = listing.backgroundColor
        updated.photoData = listing.photoData
        updated.vaccinationSummary = listing.vaccinationSummary
        updated.updatedAt = .now

        MarketplaceCloudKitMapper.apply(updated, to: record)
        let saved = try await save(record, photoData: updated.photoData)
        return try MarketplaceCloudKitMapper.listing(from: saved)
    }

    func updateListingStatus(id: String, status: MarketplaceListingStatus) async throws {
        let record = try await ownedRecord(id: id)
        record[MarketplaceCloudKitSchema.ListingField.status] = status.rawValue
        record[MarketplaceCloudKitSchema.ListingField.updatedAt] = Date.now
        _ = try await withRetry {
            try await self.database.save(record)
        }
    }

    func deleteListing(id: String) async throws {
        let record = try await ownedRecord(id: id)
        _ = try await withRetry {
            try await self.database.deleteRecord(withID: record.recordID)
        }
    }

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

    func isListingOwnedByCurrentUser(id: String) async throws -> Bool {
        let userRecordID = try await authenticatedUserRecordID()
        let record = try await record(id: id)
        return record.creatorUserRecordID == userRecordID
    }

    func reportListing(
        id: String,
        reason: MarketplaceReportReason,
        details: String?
    ) async throws {
        _ = try await authenticatedUserRecordID()
        let listingRecord = try await record(id: id)
        guard let sellerReference =
            listingRecord[MarketplaceCloudKitSchema.ListingField.sellerProfile]
            as? CKRecord.Reference else {
            throw MarketplaceError.invalidRecord
        }

        let report = CKRecord(recordType: MarketplaceCloudKitSchema.RecordType.report)
        report[MarketplaceCloudKitSchema.ReportField.listing] = CKRecord.Reference(
            record: listingRecord,
            action: .none
        )
        report[MarketplaceCloudKitSchema.ReportField.reportedSeller] = sellerReference
        report[MarketplaceCloudKitSchema.ReportField.reason] = reason.rawValue
        let trimmedDetails = details?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedDetails, !trimmedDetails.isEmpty {
            report[MarketplaceCloudKitSchema.ReportField.details] =
                String(trimmedDetails.prefix(1_000))
        } else {
            report[MarketplaceCloudKitSchema.ReportField.details] = nil
        }
        report[MarketplaceCloudKitSchema.ReportField.createdAt] = Date.now
        report[MarketplaceCloudKitSchema.ReportField.status] =
            MarketplaceReportStatus.submitted.rawValue

        _ = try await withRetry {
            try await self.database.save(report)
        }
    }

    private func record(id: String) async throws -> CKRecord {
        try await withRetry {
            try await self.database.record(for: CKRecord.ID(recordName: id))
        }
    }

    private func record(from result: Result<CKRecord, Error>) throws -> CKRecord {
        do {
            return try result.get()
        } catch let error as CKError {
            throw map(error)
        } catch {
            throw MarketplaceError.serviceUnavailable
        }
    }

    private func ownedRecord(id: String) async throws -> CKRecord {
        let userRecordID = try await authenticatedUserRecordID()
        let record = try await record(id: id)
        try authorize(record, userRecordID: userRecordID)
        return record
    }

    private func authenticatedUserRecordID() async throws -> CKRecord.ID {
        guard await accountState() == .available else {
            throw MarketplaceError.authenticationRequired
        }
        return try await withRetry {
            try await self.container.userRecordID()
        }
    }

    private func authorize(_ record: CKRecord, userRecordID: CKRecord.ID) throws {
        try MarketplaceOwnershipAuthorizer.authorize(
            creatorUserRecordID: record.creatorUserRecordID,
            currentUserRecordID: userRecordID
        )
    }

    private func save(_ record: CKRecord, photoData: Data?) async throws -> CKRecord {
        let temporaryURL = try photoData.map(makeTemporaryAsset)
        defer {
            if let temporaryURL {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        }

        record[MarketplaceCloudKitSchema.ListingField.photo] =
            temporaryURL.map(CKAsset.init(fileURL:))
        return try await withRetry {
            try await self.database.save(record)
        }
    }

    private func makeTemporaryAsset(data: Data) throws -> URL {
        let url = URL.temporaryDirectory
            .appending(path: "pawsona-marketplace-\(UUID().uuidString)")
            .appendingPathExtension("png")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func predicate(for query: MarketplaceListingQuery) -> NSPredicate {
        var predicates = [
            NSPredicate(
                format: "%K == %@",
                MarketplaceCloudKitSchema.ListingField.status,
                MarketplaceListingStatus.available.rawValue
            )
        ]

        if query.listingTypes.count == 1, let listingType = query.listingTypes.first {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.listingType,
                    listingType.rawValue
                )
            )
        }
        if let breed = query.breed, !breed.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.breed,
                    breed
                )
            )
        }
        if let sex = query.sex {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.sex,
                    sex.rawValue
                )
            )
        }
        if let region = query.region, !region.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.region,
                    region
                )
            )
        }
        if let minimumPrice = query.minimumPrice {
            predicates.append(
                NSPredicate(
                    format: "%K >= %lld",
                    MarketplaceCloudKitSchema.ListingField.priceAmount,
                    minimumPrice
                )
            )
        }
        if let maximumPrice = query.maximumPrice {
            predicates.append(
                NSPredicate(
                    format: "%K <= %lld",
                    MarketplaceCloudKitSchema.ListingField.priceAmount,
                    maximumPrice
                )
            )
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func sortDescriptors(for sort: MarketplaceSortOption) -> [NSSortDescriptor] {
        switch sort {
        case .newest:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.createdAt,
                    ascending: false
                )
            ]
        case .priceLowToHigh:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.priceAmount,
                    ascending: true
                )
            ]
        case .priceHighToLow:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.priceAmount,
                    ascending: false
                )
            ]
        }
    }

    private func withRetry<T>(
        attempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var remainingAttempts = attempts
        while true {
            do {
                return try await operation()
            } catch let error as MarketplaceError {
                throw error
            } catch let error as CKError {
                remainingAttempts -= 1
                if remainingAttempts > 0, isRetryable(error.code) {
                    let retrySeconds =
                        error.userInfo[CKErrorRetryAfterKey] as? Double ?? 1
                    try await Task.sleep(for: .milliseconds(Int64(retrySeconds * 1_000)))
                    continue
                }
                throw map(error)
            } catch {
                throw MarketplaceError.serviceUnavailable
            }
        }
    }

    private func isRetryable(_ code: CKError.Code) -> Bool {
        switch code {
        case .networkFailure, .networkUnavailable, .requestRateLimited, .serviceUnavailable,
             .zoneBusy:
            true
        default:
            false
        }
    }

    private func map(_ error: CKError) -> MarketplaceError {
        switch error.code {
        case .notAuthenticated:
            .authenticationRequired
        case .permissionFailure:
            .notAuthorized
        case .unknownItem:
            .notFound
        case .serverRecordChanged, .batchRequestFailed:
            .conflict
        case .networkFailure, .networkUnavailable:
            .networkUnavailable
        case .requestRateLimited, .zoneBusy:
            .rateLimited
        default:
            .serviceUnavailable
        }
    }

    private static func sellerProfileID(for userRecordID: CKRecord.ID) -> String {
        "seller-\(userRecordID.recordName)"
    }

    private static func sellerContactID(for profileID: String) -> String {
        "contact-\(profileID)"
    }
}
