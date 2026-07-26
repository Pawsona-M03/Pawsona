import CloudKit
import Foundation

/// Public-database CloudKit backing for the marketplace.
///
/// The implementation is split across `CloudKitMarketplaceRepository+*.swift`
/// extensions by concern — listings, seller profile, reporting, and the shared
/// CloudKit plumbing — so no single type body grows unwieldy. Stored state and
/// initialisation live here; the properties are `internal` rather than `private`
/// only so those sibling extensions can reach them.
final class CloudKitMarketplaceRepository: MarketplaceRepository {
    let container: CKContainer
    let database: CKDatabase
    let pageSize: Int
    var cursors: [String: CKQueryOperation.Cursor] = [:]

    init(container: CKContainer = .default(), pageSize: Int = 24) {
        self.container = container
        self.database = container.publicCloudDatabase
        self.pageSize = pageSize
    }
}
