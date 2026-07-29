import CloudKit
import Foundation

// MARK: - Account, record access & CloudKit plumbing

extension CloudKitMarketplaceRepository {
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

    func record(id: String) async throws -> CKRecord {
        try await withRetry {
            try await self.database.record(for: CKRecord.ID(recordName: id))
        }
    }

    func record(from result: Result<CKRecord, Error>) throws -> CKRecord {
        do {
            return try result.get()
        } catch let error as CKError {
            throw map(error)
        } catch {
            throw MarketplaceError.serviceUnavailable
        }
    }

    func ownedRecord(id: String) async throws -> CKRecord {
        let userRecordID = try await authenticatedUserRecordID()
        let record = try await record(id: id)
        try authorize(record, userRecordID: userRecordID)
        return record
    }

    /// The seller profile a record belongs to. A profile record is its own
    /// owner; listings and contacts point at one through a reference.
    func sellerProfileID(of record: CKRecord) -> String? {
        if record.recordType == MarketplaceCloudKitSchema.RecordType.sellerProfile {
            return record.recordID.recordName
        }
        let reference =
            record[MarketplaceCloudKitSchema.ListingField.sellerProfile] as? CKRecord.Reference
        return reference?.recordID.recordName
    }

    func authenticatedUserRecordID() async throws -> CKRecord.ID {
        guard await accountState() == .available else {
            throw MarketplaceError.authenticationRequired
        }
        return try await withRetry {
            try await self.container.userRecordID()
        }
    }

    func authorize(_ record: CKRecord, userRecordID: CKRecord.ID) throws {
        try MarketplaceOwnershipAuthorizer.authorize(
            creatorUserRecordID: record.creatorUserRecordID,
            recordSellerProfileID: sellerProfileID(of: record),
            currentUserRecordID: userRecordID,
            currentSellerProfileID: Self.sellerProfileID(for: userRecordID)
        )
    }

    func isOwned(_ record: CKRecord, userRecordID: CKRecord.ID) -> Bool {
        MarketplaceOwnershipAuthorizer.isOwner(
            creatorUserRecordID: record.creatorUserRecordID,
            recordSellerProfileID: sellerProfileID(of: record),
            currentUserRecordID: userRecordID,
            currentSellerProfileID: Self.sellerProfileID(for: userRecordID)
        )
    }

    func save(_ record: CKRecord, photoData: Data?) async throws -> CKRecord {
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

    func withRetry<T>(
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

    private func makeTemporaryAsset(data: Data) throws -> URL {
        let url = URL.temporaryDirectory
            .appending(path: "pawsona-marketplace-\(UUID().uuidString)")
            .appendingPathExtension("png")
        try data.write(to: url, options: .atomic)
        return url
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
        case .quotaExceeded:
            // Retrying never clears this — the user has to free up iCloud
            // space — so it needs a message of its own rather than the
            // generic "temporarily unavailable" fallback.
            .storageQuotaExceeded
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
}
