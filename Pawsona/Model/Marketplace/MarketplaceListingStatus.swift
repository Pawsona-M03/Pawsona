import Foundation

enum MarketplaceListingStatus: String, CaseIterable, Codable, Hashable, Identifiable {
    case available
    case reserved
    case sold
    case paused
    case removed

    var id: Self { self }

    /// Spelled out rather than derived from `rawValue`: the persisted `"sold"`
    /// case is part of the CloudKit schema and cannot be renamed, but it must
    /// never surface to a reader as "Sold".
    var displayName: String {
        switch self {
        case .available: "Available"
        case .reserved: "Reserved"
        case .sold: "Adopted"
        case .paused: "Paused"
        case .removed: "Removed"
        }
    }
}
