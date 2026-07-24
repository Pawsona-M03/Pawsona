import Foundation

enum PreferredContactMethod: String, CaseIterable, Codable, Hashable, Identifiable {
    case whatsApp
    case phone

    var id: Self { self }

    var displayName: String {
        switch self {
        case .whatsApp: "WhatsApp"
        case .phone: "Phone"
        }
    }
}
