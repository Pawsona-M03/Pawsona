import Foundation
import SwiftUI
import Testing
@testable import Pawsona

@Suite("Dog share card")
@MainActor
struct DogShareCardRendererTests {
    /// The card is a raster with rounded corners, so the two things that can
    /// silently break it are a nil render and a flattened alpha channel.
    @Test("Renders a transparent-cornered PNG in both appearances", arguments: [ColorScheme.light, .dark])
    func rendersPNG(colorScheme: ColorScheme) throws {
        let dog = Dog(
            name: "Nathan",
            breed: "Golden Retriever",
            dateOfBirth: Date(timeIntervalSinceNow: -60 * 60 * 24 * 730),
            weight: 6,
            sex: .male
        )
        dog.vaccineRecords = [
            VaccineRecord(vaccines: [.parvovirus, .distemper], dogList: [dog])
        ]

        let data = try #require(DogShareCardRenderer.pngData(for: dog, colorScheme: colorScheme))
        let image = try #require(UIImage(data: data))

        #expect(image.size.width == DogShareCardView.width * 2)
        #expect(image.size.height == DogShareCardView.height * 2)

        // Top-left corner sits outside the rounded rect, so it must be clear.
        let corner = try #require(image.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: 1, height: 1)))
        #expect(corner.alphaInfo != .none)

        if ProcessInfo.processInfo.environment["PAWSONA_DUMP_SHARE_CARD"] != nil {
            try data.write(to: .temporaryDirectory.appending(path: "share-card-\(colorScheme).png"))
        }
    }

    @Test("A dog with no vaccine records still renders")
    func rendersWithoutVaccineRecords() throws {
        let data = DogShareCardRenderer.pngData(for: Dog(), colorScheme: .light)
        #expect(data != nil)
    }
}
