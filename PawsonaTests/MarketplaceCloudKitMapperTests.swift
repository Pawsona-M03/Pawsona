import CloudKit
import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace CloudKit mapping")
struct MarketplaceCloudKitMapperTests {
    @Test("Listing encodes and decodes through the public record shape")
    func listingRoundTrip() throws {
        let original = MarketplaceTestFixtures.listing()
        let record = CKRecord(
            recordType: MarketplaceCloudKitSchema.RecordType.listing,
            recordID: CKRecord.ID(recordName: original.id)
        )

        MarketplaceCloudKitMapper.apply(original, to: record)
        let decoded = try MarketplaceCloudKitMapper.listing(from: record)

        #expect(decoded.id == original.id)
        #expect(decoded.sourceDogID == original.sourceDogID)
        #expect(decoded.sellerProfileID == original.sellerProfileID)
        #expect(decoded.name == original.name)
        #expect(decoded.vaccinationSummary == original.vaccinationSummary)
        #expect(decoded.listingType == original.listingType)
        #expect(decoded.priceAmount == original.priceAmount)
        #expect(record["phoneNumber"] == nil)
        #expect(record["notes"] == nil)
        #expect(record["reminders"] == nil)
        #expect(record["vaccineRecords"] == nil)
    }

    @Test("Seller contact uses a separate record linked to the seller profile")
    func sellerContactRoundTrip() throws {
        let original = SellerContact(
            sellerProfileID: "seller-1",
            whatsAppNumber: "+6281234567890",
            preferredMethod: .whatsApp
        )
        let record = CKRecord(
            recordType: MarketplaceCloudKitSchema.RecordType.sellerContact,
            recordID: CKRecord.ID(recordName: "contact-seller-1")
        )

        MarketplaceCloudKitMapper.apply(original, to: record)
        let decoded = try MarketplaceCloudKitMapper.sellerContact(from: record)

        #expect(decoded == original)
    }

    @Test("Ownership checks require the server creator record id")
    func ownership() {
        let ownerID = CKRecord.ID(recordName: "owner")
        let otherID = CKRecord.ID(recordName: "other")

        #expect(throws: Never.self) {
            try MarketplaceOwnershipAuthorizer.authorize(
                creatorUserRecordID: ownerID,
                currentUserRecordID: ownerID
            )
        }
        #expect(throws: MarketplaceError.notAuthorized) {
            try MarketplaceOwnershipAuthorizer.authorize(
                creatorUserRecordID: otherID,
                currentUserRecordID: ownerID
            )
        }
        #expect(throws: MarketplaceError.notAuthorized) {
            try MarketplaceOwnershipAuthorizer.authorize(
                creatorUserRecordID: nil,
                currentUserRecordID: ownerID
            )
        }
    }
}
