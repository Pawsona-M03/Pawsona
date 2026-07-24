import Foundation

struct MarketplacePage: Equatable {
    var listings: [MarketplaceListing]
    var nextToken: MarketplacePageToken?
}
