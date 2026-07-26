import Foundation

struct MarketplaceReport: Identifiable, Equatable, Hashable {
    var id: String
    var listingID: String
    var reportedSellerID: String
    var reason: MarketplaceReportReason
    var details: String?
    var createdAt: Date
    var status: MarketplaceReportStatus
}
