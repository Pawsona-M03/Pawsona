import Foundation
import Observation

@Observable
final class BlockedSellersViewModel {
    private(set) var sellers: [BlockedSeller] = []
    var isLoading = false

    private let repository: any MarketplaceRepository
    private let blockStore: any SellerBlocking

    init(
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking
    ) {
        self.repository = repository
        self.blockStore = blockStore
    }

    var isEmpty: Bool { sellers.isEmpty }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let identifiers = blockStore.blockedSellerIDs.sorted()
        guard !identifiers.isEmpty else {
            sellers = []
            return
        }

        var resolved: [BlockedSeller] = []
        for identifier in identifiers {
            // Resolve the seller's name for display, but never let a failed
            // lookup strand a block: fall back to a placeholder so the user
            // can always unblock.
            if let profile = try? await repository.fetchSellerProfile(id: identifier) {
                resolved.append(
                    BlockedSeller(
                        id: identifier,
                        displayName: profile.displayName,
                        region: profile.region
                    )
                )
            } else {
                resolved.append(
                    BlockedSeller(id: identifier, displayName: "Unknown lister", region: nil)
                )
            }
        }
        sellers = resolved
    }

    func unblock(_ seller: BlockedSeller) {
        blockStore.unblock(seller.id)
        sellers.removeAll { $0.id == seller.id }
    }
}
