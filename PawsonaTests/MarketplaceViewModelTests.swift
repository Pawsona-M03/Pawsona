import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace view models")
@MainActor
struct MarketplaceViewModelTests {
    @Test("Browse filters search results and excludes blocked sellers")
    func browseAndBlockFiltering() async {
        let repository = FakeMarketplaceRepository()
        repository.listings = [
            MarketplaceTestFixtures.listing(
                id: "berry",
                sellerProfileID: "seller-1",
                name: "Berry",
                breed: "Labrador"
            ),
            MarketplaceTestFixtures.listing(
                id: "milo",
                sellerProfileID: "seller-2",
                name: "Milo",
                breed: "Poodle"
            )
        ]
        let blocks = InMemorySellerBlockStore()
        blocks.block("seller-2")
        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: blocks
        )

        await viewModel.reload()
        #expect(viewModel.visibleListings.map(\.id) == ["berry"])

        viewModel.query.searchText = "poodle"
        #expect(viewModel.visibleListings.isEmpty)

        blocks.unblock("seller-2")
        viewModel.refreshBlockedSellers()
        #expect(viewModel.visibleListings.map(\.id) == ["milo"])
    }

    @Test("Browse exposes offline and recoverable error state")
    func browseErrorState() async {
        let repository = FakeMarketplaceRepository()
        repository.fetchError = MarketplaceError.networkUnavailable
        let viewModel = MarketplaceBrowseViewModel(
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.reload()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.isOffline)
        #expect(viewModel.errorMessage == MarketplaceError.networkUnavailable.localizedDescription)
    }

    @Test("Detail loads seller and ownership, then transitions status")
    func ownerStatusTransition() async {
        let listing = MarketplaceTestFixtures.listing()
        let repository = FakeMarketplaceRepository()
        repository.listings = [listing]
        repository.profile = MarketplaceTestFixtures.sellerProfile()
        repository.isOwner = true
        let viewModel = MarketplaceDetailViewModel(
            listing: listing,
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.load()
        await viewModel.updateStatus(.reserved)

        #expect(viewModel.isOwner)
        #expect(viewModel.sellerProfile?.displayName == "Nathan")
        #expect(viewModel.listing.status == .reserved)
        #expect(repository.statusUpdates.count == 1)
        #expect(repository.statusUpdates.first?.0 == listing.id)
        #expect(repository.statusUpdates.first?.1 == .reserved)
    }

    @Test("Contact and reports require authenticated iCloud")
    func unauthenticatedActions() async {
        let listing = MarketplaceTestFixtures.listing()
        let repository = FakeMarketplaceRepository()
        repository.listings = [listing]
        repository.profile = MarketplaceTestFixtures.sellerProfile()
        repository.account = .noAccount
        let viewModel = MarketplaceDetailViewModel(
            listing: listing,
            repository: repository,
            blockStore: InMemorySellerBlockStore()
        )

        await viewModel.revealContact()
        #expect(viewModel.sellerContact == nil)
        #expect(viewModel.errorMessage == MarketplaceError.authenticationRequired.localizedDescription)

        let submitted = await viewModel.submitReport(reason: .suspectedScam, details: nil)
        #expect(!submitted)
        #expect(repository.submittedReports.isEmpty)
    }

    @Test("Publishing stops at the iCloud requirement when signed out")
    func publishingRequiresICloud() async {
        let repository = FakeMarketplaceRepository()
        repository.account = .noAccount
        let viewModel = MarketplacePublishingViewModel(repository: repository)

        await viewModel.prepare()

        if case let .requiresICloud(message) = viewModel.step {
            #expect(message.localizedStandardContains("iCloud"))
        } else {
            Issue.record("Expected the publishing flow to require iCloud")
        }
    }

    @Test("Complete seller profile advances to listing confirmation")
    func existingSellerProfile() async {
        let repository = FakeMarketplaceRepository()
        repository.profile = MarketplaceTestFixtures.sellerProfile()
        let viewModel = MarketplacePublishingViewModel(repository: repository)

        await viewModel.prepare()

        if case .confirmation = viewModel.step {
            #expect(viewModel.sellerProfile?.profileComplete == true)
        } else {
            Issue.record("Expected listing confirmation for a complete seller")
        }
    }

    @Test("A full iCloud account surfaces a storage warning instead of the generic failure")
    func publishingReportsFullICloudStorage() async {
        let repository = FakeMarketplaceRepository()
        repository.profile = MarketplaceTestFixtures.sellerProfile()
        repository.publishError = MarketplaceError.storageQuotaExceeded
        let viewModel = MarketplacePublishingViewModel(repository: repository)

        await viewModel.prepare()
        viewModel.listingType = .adoption
        viewModel.acceptedPublicSharing = true
        viewModel.acceptedContactSharing = true
        await viewModel.publish(puppy: MarketplaceTestFixtures.puppySnapshot())

        #expect(viewModel.errorMessage?.localizedStandardContains("iCloud storage is full") == true)
        #expect(repository.listings.isEmpty)
        if case .published = viewModel.step {
            Issue.record("Publishing must not report success when storage is full")
        }
    }
}
