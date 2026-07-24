import Foundation
@testable import Pawsona

final class InMemorySellerBlockStore: SellerBlocking {
    private(set) var blockedSellerIDs: Set<String> = []

    func isBlocked(_ sellerID: String) -> Bool {
        blockedSellerIDs.contains(sellerID)
    }

    func block(_ sellerID: String) {
        blockedSellerIDs.insert(sellerID)
    }

    func unblock(_ sellerID: String) {
        blockedSellerIDs.remove(sellerID)
    }
}
