import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace own-listing awareness")
@MainActor
struct MarketplaceOwnListingTests {
    @Test("Browse recognises the signed-in seller's own listing")
    func recognisesOwnListing() async {
        let repository = FakeMarketplaceRepository()
        repository.profile = MarketplaceTestFixtures.sellerProfile(id: "seller-1")
        repository.listings = [
            MarketplaceTestFixtures.listing(id: "mine", sellerProfileID: "seller-1"),
            MarketplaceTestFixtures.listing(id: "theirs", sellerProfileID: "seller-2")
        ]
        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.loadCurrentSeller()
        await viewModel.reload()

        #expect(viewModel.isOwnListing(repository.listings[0]))
        #expect(!viewModel.isOwnListing(repository.listings[1]))
    }

    @Test("A self-block never hides the user's own listing")
    func selfBlockDoesNotHideOwnListing() async {
        let repository = FakeMarketplaceRepository()
        repository.profile = MarketplaceTestFixtures.sellerProfile(id: "seller-1")
        repository.listings = [
            MarketplaceTestFixtures.listing(id: "mine", sellerProfileID: "seller-1"),
            MarketplaceTestFixtures.listing(id: "theirs", sellerProfileID: "seller-2")
        ]
        let blocks = InMemorySellerBlockStore()
        // The exact trap this fixes: the user blocked their own seller profile
        // and their puppy silently vanished from Marketplace.
        blocks.block("seller-1")
        blocks.block("seller-2")

        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: blocks
        )
        await viewModel.loadCurrentSeller()
        await viewModel.reload()

        #expect(viewModel.visibleListings.map(\.id) == ["mine"])
    }

    @Test("The owner cannot block themselves from the detail screen")
    func ownerCannotSelfBlock() {
        let repository = FakeMarketplaceRepository()
        let blocks = InMemorySellerBlockStore()
        let viewModel = MarketplaceDetailViewModel(
            listing: MarketplaceTestFixtures.listing(sellerProfileID: "seller-1"),
            repository: repository,
            blockStore: blocks,
            isKnownOwnListing: true
        )

        #expect(!viewModel.canReportOrBlock)

        viewModel.blockSeller()

        #expect(blocks.blockedSellerIDs.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("A failed page-two fetch keeps page one and stays out of the way")
    func pagingFailureIsNonBlocking() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [MarketplaceTestFixtures.listing(id: "berry")]
        repository.nextTokenForFirstPage = MarketplacePageToken(rawValue: "cursor-1")
        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.reload()
        #expect(viewModel.errorMessage == nil)

        repository.errorAfterFirstFetch = MarketplaceError.serviceUnavailable
        await viewModel.loadNextPage()

        // The grid keeps working; the failure is a note, not a takeover.
        #expect(viewModel.visibleListings.map(\.id) == ["berry"])
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.noticeMessage == MarketplaceError.serviceUnavailable.localizedDescription)
    }

    @Test("A failed refresh over loaded content demotes the error to a notice")
    func failedRefreshKeepsStaleResults() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [MarketplaceTestFixtures.listing(id: "berry")]
        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.reload()
        #expect(viewModel.visibleListings.count == 1)

        repository.fetchError = MarketplaceError.networkUnavailable
        await viewModel.reload()

        #expect(viewModel.visibleListings.map(\.id) == ["berry"])
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.noticeMessage == MarketplaceError.networkUnavailable.localizedDescription)
    }
}
