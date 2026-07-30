import Foundation

/// A seller the user has blocked, resolved to a display name for the
/// Blocked Sellers management screen. `id` is the seller's profile record name.
struct BlockedSeller: Identifiable, Equatable {
    let id: String
    let displayName: String
    let region: String?
}
