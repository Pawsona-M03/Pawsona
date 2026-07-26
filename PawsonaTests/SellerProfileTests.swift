import Foundation
import Testing
@testable import Pawsona

@Suite("Seller profile")
struct SellerProfileTests {
    @Test("Required seller fields and rules acceptance determine completeness")
    func completeness() {
        var profile = MarketplaceTestFixtures.sellerProfile()
        #expect(profile.hasRequiredFields)

        profile.displayName = " "
        #expect(!profile.hasRequiredFields)

        profile = MarketplaceTestFixtures.sellerProfile()
        profile.region = ""
        #expect(!profile.hasRequiredFields)

        profile = MarketplaceTestFixtures.sellerProfile()
        profile.rulesAcceptedAt = nil
        #expect(!profile.hasRequiredFields)
    }

    @Test("Complete profile explanation does not claim identity verification")
    func disclaimer() {
        let explanation = MarketplaceTestFixtures.sellerProfile().completenessExplanation
        #expect(explanation.contains("provided all required"))
        #expect(explanation.contains("not independently verified"))
        #expect(!explanation.localizedStandardContains("Verified Seller"))
    }
}
