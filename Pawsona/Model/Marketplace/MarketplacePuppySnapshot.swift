import Foundation

struct MarketplacePuppySnapshot: Equatable, Hashable {
    var sourceDogID: String
    var name: String
    var breed: String
    var dateOfBirth: Date?
    var sex: Sex?
    var weight: Double?
    var backgroundColor: ColorType
    var photoData: Data?
    var vaccinationSummary: MarketplaceVaccinationSummary
}
