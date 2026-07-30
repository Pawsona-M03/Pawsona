import CloudKit
import Foundation

enum MarketplaceOwnershipAuthorizer {
    /// Decides whether a public-database record belongs to the signed-in user.
    ///
    /// Two independent proofs, because neither is reliable alone:
    ///
    /// - **Seller profile.** A profile id is derived from the user record name
    ///   (`seller-<recordName>`), so a listing pointing at ours was published by
    ///   us. This is the same signal Browse uses to badge "Your listing", which
    ///   is why the badge and the owner controls used to disagree.
    /// - **Creator metadata.** `creatorUserRecordID` comes back as CloudKit's
    ///   current-user placeholder — not the real user record name — for records
    ///   the signed-in user created in the public database, so comparing it
    ///   against `CKContainer.userRecordID()` was false for the one person it
    ///   had to be true for. Accept both spellings.
    ///
    /// This gate is about showing the right controls, not about security: the
    /// public database is owner-writable, so CloudKit rejects a write to
    /// someone else's record no matter what this returns.
    static func isOwner(
        creatorUserRecordID: CKRecord.ID?,
        recordSellerProfileID: String?,
        currentUserRecordID: CKRecord.ID,
        currentSellerProfileID: String
    ) -> Bool {
        if let recordSellerProfileID, recordSellerProfileID == currentSellerProfileID {
            return true
        }
        guard let creatorRecordName = creatorUserRecordID?.recordName else { return false }
        return creatorRecordName == currentUserRecordID.recordName
            || creatorRecordName == CKCurrentUserDefaultName
    }

    static func authorize(
        creatorUserRecordID: CKRecord.ID?,
        recordSellerProfileID: String?,
        currentUserRecordID: CKRecord.ID,
        currentSellerProfileID: String
    ) throws {
        guard
            isOwner(
                creatorUserRecordID: creatorUserRecordID,
                recordSellerProfileID: recordSellerProfileID,
                currentUserRecordID: currentUserRecordID,
                currentSellerProfileID: currentSellerProfileID
            )
        else {
            throw MarketplaceError.notAuthorized
        }
    }
}
