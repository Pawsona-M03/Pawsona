import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace contact")
struct MarketplaceContactTests {
    @Test("Indonesian local and international phone numbers normalize to E.164")
    func phoneNormalization() throws {
        #expect(try MarketplacePhoneNumber.normalize("0812 3456-7890") == "+6281234567890")
        #expect(try MarketplacePhoneNumber.normalize("+62 (812) 3456 7890") == "+6281234567890")
        #expect(try MarketplacePhoneNumber.normalize("6281234567890") == "+6281234567890")
    }

    @Test("Invalid or ambiguous phone numbers are rejected")
    func rejectsInvalidPhoneNumbers() {
        #expect(throws: MarketplaceError.invalidPhoneNumber) {
            _ = try MarketplacePhoneNumber.normalize("81234567890")
        }
        #expect(throws: MarketplaceError.invalidPhoneNumber) {
            _ = try MarketplacePhoneNumber.normalize("+62-call-me")
        }
    }

    @Test("WhatsApp URL uses international digits and percent-encoded puppy message")
    func whatsappURL() throws {
        let url = try WhatsAppURLBuilder.url(
            number: "+62 812 3456 7890",
            puppyName: "Berry & Coco"
        )
        #expect(url.scheme == "https")
        #expect(url.host == "wa.me")
        #expect(url.path == "/6281234567890")

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let message = try #require(components.queryItems?.first(where: { $0.name == "text" })?.value)
        #expect(message == "Hi, I found Berry & Coco’s listing on Pawsona. Is Berry & Coco still available?")
        #expect(url.absoluteString.contains("%26"))
    }
}
