import Foundation
import Testing
@testable import Pawsona

@Suite("Seller blocking")
@MainActor
struct SellerBlockStoreTests {
    @Test("Blocking is persisted and can be reversed")
    func persistence() throws {
        let suiteName = "SellerBlockStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = UserDefaultsSellerBlockStore(
            defaults: defaults,
            storageKey: "blocked"
        )
        firstStore.block("seller-1")

        let secondStore = UserDefaultsSellerBlockStore(
            defaults: defaults,
            storageKey: "blocked"
        )
        #expect(secondStore.isBlocked("seller-1"))

        secondStore.unblock("seller-1")
        #expect(!firstStore.isBlocked("seller-1"))
    }
}
