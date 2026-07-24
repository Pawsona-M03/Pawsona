import CloudKit
import Foundation

enum MarketplaceOwnershipAuthorizer {
    static func authorize(
        creatorUserRecordID: CKRecord.ID?,
        currentUserRecordID: CKRecord.ID
    ) throws {
        guard creatorUserRecordID == currentUserRecordID else {
            throw MarketplaceError.notAuthorized
        }
    }
}
