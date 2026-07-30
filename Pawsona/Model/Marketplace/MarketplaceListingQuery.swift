import Foundation

struct MarketplaceListingQuery: Equatable, Hashable {
    var searchText = ""
    var listingTypes: Set<MarketplaceListingType> = []
    var breed: String?
    var sex: Sex?
    var region: String?
    var minimumPrice: Int64?
    var maximumPrice: Int64?
    var sort: MarketplaceSortOption = .newest

    var hasFilters: Bool {
        !listingTypes.isEmpty
            || breed != nil
            || sex != nil
            || region != nil
            || minimumPrice != nil
            || maximumPrice != nil
    }

    func matches(_ listing: MarketplaceListing) -> Bool {
        guard listing.status == .available else { return false }

        if !searchText.isEmpty,
           !listing.name.localizedStandardContains(searchText),
           !listing.breed.localizedStandardContains(searchText) {
            return false
        }
        if !listingTypes.isEmpty, !listingTypes.contains(listing.listingType) {
            return false
        }
        if let breed, !breed.isEmpty, listing.breed != breed {
            return false
        }
        if let sex, listing.sex != sex {
            return false
        }
        if let region, !region.isEmpty, listing.region != region {
            return false
        }
        if let minimumPrice {
            guard listing.listingType == .sale,
                  let price = listing.priceAmount,
                  price >= minimumPrice else {
                return false
            }
        }
        if let maximumPrice {
            guard listing.listingType == .sale,
                  let price = listing.priceAmount,
                  price <= maximumPrice else {
                return false
            }
        }
        return true
    }

    func sorted(_ listings: [MarketplaceListing]) -> [MarketplaceListing] {
        listings.sorted { first, second in
            switch sort {
            case .newest:
                first.createdAt > second.createdAt
            case .priceLowToHigh:
                comparablePrice(for: first, adoptionPrice: Int64.min)
                    < comparablePrice(for: second, adoptionPrice: Int64.min)
            case .priceHighToLow:
                comparablePrice(for: first, adoptionPrice: Int64.min)
                    > comparablePrice(for: second, adoptionPrice: Int64.min)
            }
        }
    }

    private func comparablePrice(for listing: MarketplaceListing, adoptionPrice: Int64) -> Int64 {
        listing.listingType == .adoption ? adoptionPrice : listing.priceAmount ?? adoptionPrice
    }
}
