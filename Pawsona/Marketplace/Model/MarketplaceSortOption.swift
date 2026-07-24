import Foundation

enum MarketplaceSortOption: String, CaseIterable, Hashable, Identifiable {
    case newest
    case priceLowToHigh
    case priceHighToLow

    var id: Self { self }

    var displayName: String {
        switch self {
        case .newest: "Newest"
        case .priceLowToHigh: "Price: Low to High"
        case .priceHighToLow: "Price: High to Low"
        }
    }
}
