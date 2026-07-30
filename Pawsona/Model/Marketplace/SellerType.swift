import Foundation

enum SellerType: String, CaseIterable, Codable, Hashable, Identifiable {
    case individual
    case breeder
    case rescue

    var id: Self { self }

    var displayName: String {
        rawValue.capitalized
    }
}
