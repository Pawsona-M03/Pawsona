import Foundation

enum MarketplaceListingType: String, CaseIterable, Codable, Hashable, Identifiable {
    case sale
    case adoption

    var id: Self { self }

    var displayName: String {
        switch self {
        case .sale: "For sale"
        case .adoption: "Adoption"
        }
    }
}
