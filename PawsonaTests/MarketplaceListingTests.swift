import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace listing")
struct MarketplaceListingTests {
    @Test("Sale listings require a positive price")
    func saleValidation() {
        var listing = MarketplaceTestFixtures.listing(priceAmount: 1)
        #expect(throws: Never.self) {
            _ = try listing.validated()
        }

        listing.priceAmount = 0
        #expect(throws: MarketplaceError.invalidSalePrice) {
            _ = try listing.validated()
        }

        listing.priceAmount = nil
        #expect(throws: MarketplaceError.invalidSalePrice) {
            _ = try listing.validated()
        }
    }

    @Test("Adoption listings reject a price and display Free adoption")
    func adoptionValidation() {
        var listing = MarketplaceTestFixtures.listing(
            listingType: .adoption,
            priceAmount: nil
        )
        #expect(throws: Never.self) {
            _ = try listing.validated()
        }
        #expect(listing.priceText == "Free adoption")

        listing.priceAmount = 100
        #expect(throws: MarketplaceError.adoptionCannotHavePrice) {
            _ = try listing.validated()
        }
    }

    @Test("Sale prices use localized IDR formatting")
    func idrFormatting() {
        let price = MarketplaceTestFixtures.listing(priceAmount: 2_500_000).priceText
        #expect(price.contains("Rp"))
        #expect(price.contains("2.500.000"))
    }

    @Test("Search, filters, and sorting use marketplace values")
    func queryBehavior() {
        let older = MarketplaceTestFixtures.listing(
            id: "older",
            name: "Berry",
            breed: "Labrador Retriever",
            priceAmount: 3_000_000,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = MarketplaceTestFixtures.listing(
            id: "newer",
            name: "Milo",
            breed: "Poodle",
            priceAmount: 1_000_000,
            createdAt: Date(timeIntervalSince1970: 200)
        )

        var query = MarketplaceListingQuery(searchText: "lab")
        #expect(query.matches(older))
        #expect(!query.matches(newer))

        query = MarketplaceListingQuery(
            listingTypes: [.sale],
            region: "Jakarta",
            minimumPrice: 2_000_000,
            maximumPrice: 4_000_000,
            sort: .priceLowToHigh
        )
        #expect(query.matches(older))
        #expect(!query.matches(newer))
        #expect(query.sorted([older, newer]).map(\.id) == ["newer", "older"])
    }
}
