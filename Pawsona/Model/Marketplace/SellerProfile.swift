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

    /// Shown both on a published profile card and in the profile form, so it
    /// lives here rather than being duplicated as a literal in each view.
    static let completenessExplanation = """
        This lister has provided all required contact and profile information. \
        Pawsona has not independently verified their identity.
        """

    var completenessExplanation: String {
        Self.completenessExplanation
    }
}
