import Foundation

enum MarketplaceListingStatus: String, CaseIterable, Codable, Hashable, Identifiable {
    case available
    case reserved
    case sold
    case paused
    case removed

    var id: Self { self }

    var displayName: String {
        rawValue.capitalized
    }
}
