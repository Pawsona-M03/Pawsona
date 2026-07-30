import Foundation

enum MarketplaceReportReason: String, CaseIterable, Codable, Hashable, Identifiable {
    case suspectedScam
    case inaccurateInformation
    case prohibitedContent
    case animalWelfare
    case other

    var id: Self { self }

    var displayName: String {
        switch self {
        case .suspectedScam: "Suspected scam"
        case .inaccurateInformation: "Inaccurate information"
        case .prohibitedContent: "Prohibited content"
        case .animalWelfare: "Animal welfare concern"
        case .other: "Other"
        }
    }
}
