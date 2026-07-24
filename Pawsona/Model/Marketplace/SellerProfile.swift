import Foundation

struct SellerProfile: Identifiable, Equatable, Hashable {
    var id: String
    var creatorRecordName: String?
    var displayName: String
    var region: String
    var sellerType: SellerType
    var joinedAt: Date
    var profileComplete: Bool
    var rulesAcceptedAt: Date?

    var hasRequiredFields: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && rulesAcceptedAt != nil
    }

    var completenessExplanation: String {
        """
        This seller has provided all required contact and profile information. \
        Pawsona has not independently verified their identity.
        """
    }
}
