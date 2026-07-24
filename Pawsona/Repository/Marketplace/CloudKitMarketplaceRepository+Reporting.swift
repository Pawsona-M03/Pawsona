import CloudKit
import Foundation

// MARK: - Reporting

extension CloudKitMarketplaceRepository {
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
}
