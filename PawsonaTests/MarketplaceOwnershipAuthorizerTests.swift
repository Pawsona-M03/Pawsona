import CloudKit
import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace ownership")
struct MarketplaceOwnershipAuthorizerTests {
    private let currentUserID = CKRecord.ID(recordName: "_me")
    private let currentProfileID = "seller-_me"

    @Test("The creator's own record id proves ownership")
    func creatorRecordIDMatches() {
        #expect(
            MarketplaceOwnershipAuthorizer.isOwner(
                creatorUserRecordID: currentUserID,
                recordSellerProfileID: currentProfileID,
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        )
    }

    /// The regression behind "only the listing owner can make this change" on
    /// your own listing: the public database reports the signed-in user as the
    /// placeholder owner, never their real user record name.
    @Test("CloudKit's placeholder creator still proves ownership")
    func placeholderCreatorMatches() {
        #expect(
            MarketplaceOwnershipAuthorizer.isOwner(
                creatorUserRecordID: CKRecord.ID(recordName: CKCurrentUserDefaultName),
                recordSellerProfileID: nil,
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        )
    }

    /// Seller profile ids are derived from the user record name, so a listing
    /// carrying ours was published by us — whatever the creator metadata says.
    @Test("A listing carrying our seller profile is ours")
    func sellerProfileMatches() {
        #expect(
            MarketplaceOwnershipAuthorizer.isOwner(
                creatorUserRecordID: nil,
                recordSellerProfileID: currentProfileID,
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        )
    }

    @Test("Another seller's listing is never ours")
    func strangerListingRejected() {
        #expect(
            !MarketplaceOwnershipAuthorizer.isOwner(
                creatorUserRecordID: CKRecord.ID(recordName: "_someone-else"),
                recordSellerProfileID: "seller-_someone-else",
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        )
    }

    @Test("Ownership fails closed when the record carries no proof at all")
    func missingProofRejected() {
        #expect(
            !MarketplaceOwnershipAuthorizer.isOwner(
                creatorUserRecordID: nil,
                recordSellerProfileID: nil,
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        )
    }

    @Test("Authorizing a record we do not own reports the owner-only error")
    func authorizeThrowsForStranger() {
        #expect(throws: MarketplaceError.notAuthorized) {
            try MarketplaceOwnershipAuthorizer.authorize(
                creatorUserRecordID: CKRecord.ID(recordName: "_someone-else"),
                recordSellerProfileID: "seller-_someone-else",
                currentUserRecordID: currentUserID,
                currentSellerProfileID: currentProfileID
            )
        }
    }
}
