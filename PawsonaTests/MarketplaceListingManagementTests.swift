import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace listing management")
@MainActor
struct MarketplaceListingManagementTests {
    @Test("Editing terms switches a sale to a free adoption and drops the price")
    func editTermsToAdoption() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [
            MarketplaceTestFixtures.listing(listingType: .sale, priceAmount: 2_500_000)
        ]
        let viewModel = MarketplaceListingTermsViewModel(
            listing: repository.listings[0],
            repository: repository
        )

        #expect(viewModel.priceText == "2500000")

        viewModel.listingType = .adoption
        let updated = await viewModel.save()

        #expect(updated?.listingType == .adoption)
        #expect(updated?.priceAmount == nil)
        #expect(updated?.priceText == "Free adoption")
        #expect(repository.termsUpdates.count == 1)
    }

    @Test("Editing terms saves a new sale price")
    func editTermsNewPrice() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [MarketplaceTestFixtures.listing(priceAmount: 2_500_000)]
        let viewModel = MarketplaceListingTermsViewModel(
            listing: repository.listings[0],
            repository: repository
        )

        viewModel.priceText = "1.750.000"
        #expect(viewModel.canSave)

        let updated = await viewModel.save()

        #expect(updated?.priceAmount == 1_750_000)
        #expect(repository.listings[0].priceAmount == 1_750_000)
    }

    @Test("A sale with no usable price cannot be saved")
    func editTermsRejectsEmptyPrice() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [MarketplaceTestFixtures.listing()]
        let viewModel = MarketplaceListingTermsViewModel(
            listing: repository.listings[0],
            repository: repository
        )

        viewModel.priceText = "  "
        #expect(!viewModel.canSave)

        let updated = await viewModel.save()

        #expect(updated == nil)
        #expect(viewModel.errorMessage == MarketplaceError.invalidSalePrice.localizedDescription)
        #expect(repository.termsUpdates.isEmpty)
    }
}
