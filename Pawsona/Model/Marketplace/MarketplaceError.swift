import Foundation

enum MarketplaceError: Error, Equatable, LocalizedError {
    case invalidSalePrice
    case adoptionCannotHavePrice
    case incompleteSellerProfile
    case invalidPhoneNumber
    case authenticationRequired
    case notAuthorized
    case notFound
    case conflict
    case networkUnavailable
    case rateLimited
    case invalidRecord
    case unsupportedContactMethod
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidSalePrice:
            "Enter a sale price greater than zero."
        case .adoptionCannotHavePrice:
            "Adoption listings cannot include a price."
        case .incompleteSellerProfile:
            "Complete all required seller profile fields first."
        case .invalidPhoneNumber:
            "Enter a valid international WhatsApp number."
        case .authenticationRequired:
            "Sign in to iCloud to continue."
        case .notAuthorized:
            "Only the listing owner can make this change."
        case .notFound:
            "This marketplace item is no longer available."
        case .conflict:
            "This listing changed elsewhere. Refresh and try again."
        case .networkUnavailable:
            "You're offline. Check your connection and try again."
        case .rateLimited:
            "Marketplace is receiving too many requests. Please try again shortly."
        case .invalidRecord:
            "Pawsona could not read this marketplace item."
        case .unsupportedContactMethod:
            "This seller's contact method is not supported."
        case .serviceUnavailable:
            "Marketplace is temporarily unavailable. Please try again."
        }
    }
}
