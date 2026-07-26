import Foundation
@testable import Pawsona

/// One `updateListingTerms` call recorded by `FakeMarketplaceRepository`.
struct RecordedTermsUpdate: Equatable {
    let listingID: String
    let listingType: MarketplaceListingType
    let priceAmount: Int64?
}
