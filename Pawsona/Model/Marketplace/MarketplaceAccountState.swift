import Foundation

enum MarketplaceAccountState: Equatable {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    var requiresSignInMessage: String? {
        switch self {
        case .available:
            nil
        case .noAccount:
            "Sign in to iCloud in Settings to publish, manage, report, or contact listers in the Adoption Hub."
        case .restricted:
            "This iCloud account is restricted and cannot use authenticated Adoption Hub actions."
        case .couldNotDetermine, .temporarilyUnavailable:
            "Pawsona could not confirm your iCloud account. Check your connection and try again."
        }
    }
}
