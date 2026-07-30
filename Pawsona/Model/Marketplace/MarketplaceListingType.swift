import Foundation

enum MarketplaceListingType: String, CaseIterable, Codable, Hashable, Identifiable {
    case sale
    case adoption

    var id: Self { self }

    var displayName: String {
        switch self {
        case .sale: "Adoption fee"
        case .adoption: "Free"
        }
    }
}
