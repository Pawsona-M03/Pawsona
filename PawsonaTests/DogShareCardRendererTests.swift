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

    /// `ImageRenderer` does not inherit the app's environment, so the injected
    /// colour scheme is the only thing making the dark card dark. If that
    /// injection ever stops working the picker silently offers two identical
    /// cards, which no size or alpha assertion would catch.
    @Test("The two appearances render differently")
    func appearancesDiffer() throws {
        let dog = Dog(name: "Nathan", breed: "Golden Retriever")

        let light = try #require(DogShareCardRenderer.pngData(for: dog, colorScheme: .light))
        let dark = try #require(DogShareCardRenderer.pngData(for: dog, colorScheme: .dark))

        #expect(light != dark)
    }

    /// A brand-new puppy has no records at all, and the vaccine section is left
    /// empty rather than growing placeholder text.
    @Test("A dog with no vaccine records still renders at the same size")
    func rendersWithoutVaccineRecords() throws {
        let data = try #require(DogShareCardRenderer.pngData(for: Dog(), colorScheme: .light))
        let image = try #require(UIImage(data: data))

        #expect(image.size.width == DogShareCardView.width * 2)
        #expect(image.size.height == DogShareCardView.height * 2)
    }
}
