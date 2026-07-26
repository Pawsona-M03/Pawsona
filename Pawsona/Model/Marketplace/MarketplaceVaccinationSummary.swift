import Foundation

struct MarketplaceVaccinationSummary: Codable, Equatable, Hashable {
    var vaccineNames: [String]
    var recordCount: Int

    var displayText: String {
        guard recordCount > 0 else {
            return "No vaccination summary provided"
        }

        let countText = recordCount == 1 ? "1 record" : "\(recordCount) records"
        guard !vaccineNames.isEmpty else {
            return countText
        }
        return "\(vaccineNames.joined(separator: ", ")) · \(countText)"
    }
}
