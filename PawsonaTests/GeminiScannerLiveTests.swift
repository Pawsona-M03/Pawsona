//// Commented for now, save api usage
////
////  GeminiScannerLiveTests.swift
////  PawsonaTests
////
////  Sends the real vaccine books in Fixtures/ to the real Gemini API and checks
////  the answer against hand-verified ground truth. This is the only thing that
////  catches an accuracy regression after a prompt or model change, so it runs on
////  every CI pass — Xcode Cloud materialises the key via ci_scripts/ci_post_clone.sh.
////
////  If it fails, look at ScannedVisit.inkMarksSeen in the failure message first:
////  it says which checkbox the model thought carried pen ink.
////
//
//import Foundation
//import Testing
//import UIKit
//@testable import Pawsona
//
//@Suite("Gemini vaccine book scanning", .serialized)
//struct GeminiScannerLiveTests {
//    /// Every visit a human can read off one of the fixture pages.
//    struct ExpectedVisit {
//        var dateGiven: DateComponents
//        var vaccines: Set<VaccineType>
//    }
//
//    @Test("Eurican pet health check book, two visits on one page")
//    func euricanBook() async throws {
//        try await expect(
//            fixture: "PetHealthCheckEurican",
//            visits: [
//                ExpectedVisit(
//                    dateGiven: DateComponents(year: 2020, month: 5, day: 26),
//                    vaccines: [.parvovirus, .distemper, .parainfluenza, .hepatitis, .leptospira]
//                ),
//                ExpectedVisit(
//                    dateGiven: DateComponents(year: 2020, month: 6, day: 12),
//                    vaccines: [.rabies]
//                )
//            ]
//        )
//    }
//
//    /// The Nobivac book prints a solid teal icon as the checkbox and carries a
//    /// "Nobivac DHP" sticker. Only three rows have pen ink; neither the printed
//    /// icons nor the sticker may add a fourth.
//    @Test("Nobivac Indonesian book, printed checkboxes must not read as ticks")
//    func nobivacBook() async throws {
//        try await expect(
//            fixture: "NobivacIndonesian",
//            visits: [
//                ExpectedVisit(
//                    dateGiven: DateComponents(year: 2025, month: 9, day: 6),
//                    vaccines: [.distemper, .parvovirus, .hepatitis]
//                )
//            ]
//        )
//    }
//
//    private func expect(fixture: String, visits expected: [ExpectedVisit]) async throws {
//        let scanned: [ScannedVisit]
//
//        do {
//            scanned = try await GeminiScanner.scan(Self.image(named: fixture))
//        } catch GeminiScanner.ScanError.quotaExceeded {
//            // The free tier allows 20 requests a day across the whole key, and the
//            // app shares it. Running out says nothing about scan accuracy, so warn
//            // instead of failing the build.
//            Issue.record(
//                Comment(rawValue: "Skipped \(fixture): Gemini quota exhausted, not an accuracy failure."),
//                severity: .warning
//            )
//            return
//        }
//
//        let transcript = scanned.map(\.inkMarksSeen).joined(separator: "\n")
//
//        #expect(
//            scanned.count == expected.count,
//            "\(fixture): expected \(expected.count) visits, got \(scanned.count).\n\(transcript)"
//        )
//
//        for (index, expectedVisit) in expected.enumerated() {
//            guard index < scanned.count else { break }
//            let visit = scanned[index]
//
//            #expect(
//                Set(visit.vaccines) == expectedVisit.vaccines,
//                """
//                \(fixture) visit \(index + 1): expected \
//                \(expectedVisit.vaccines.map(\.rawValue).sorted()), got \
//                \(visit.vaccines.map(\.rawValue).sorted()).
//                \(visit.inkMarksSeen)
//                """
//            )
//
//            let expectedDate = Calendar.current.date(from: expectedVisit.dateGiven)
//            #expect(
//                visit.dateGiven == expectedDate,
//                """
//                \(fixture) visit \(index + 1): expected date \
//                \(expectedDate?.description ?? "nil"), got \(visit.dateGiven?.description ?? "nil")
//                """
//            )
//        }
//    }
//
//    /// Fixtures ship in the test bundle, not the app bundle that hosts it.
//    private static func image(named name: String) throws -> UIImage {
//        let bundle = Bundle(for: BundleToken.self)
//        let url = try #require(
//            bundle.url(forResource: name, withExtension: "jpeg"),
//            Comment(rawValue: "Missing PawsonaTests/Fixtures/\(name).jpeg in the test bundle")
//        )
//        return try #require(
//            UIImage(data: try Data(contentsOf: url)),
//            Comment(rawValue: "\(name).jpeg is not a readable image")
//        )
//    }
//}
//
///// Swift Testing suites are structs, so `Bundle(for:)` needs a class to anchor to.
//private final class BundleToken {}
