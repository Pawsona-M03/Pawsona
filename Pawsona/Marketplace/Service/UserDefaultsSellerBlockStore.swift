import Foundation

final class UserDefaultsSellerBlockStore: SellerBlocking {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "marketplace.blockedSellerIDs"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    var blockedSellerIDs: Set<String> {
        Set(defaults.stringArray(forKey: storageKey) ?? [])
    }

    func isBlocked(_ sellerID: String) -> Bool {
        blockedSellerIDs.contains(sellerID)
    }

    func block(_ sellerID: String) {
        var identifiers = blockedSellerIDs
        identifiers.insert(sellerID)
        defaults.set(identifiers.sorted(), forKey: storageKey)
    }

    func unblock(_ sellerID: String) {
        var identifiers = blockedSellerIDs
        identifiers.remove(sellerID)
        defaults.set(identifiers.sorted(), forKey: storageKey)
    }
}
