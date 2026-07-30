//
//  DogDraftWeightTests.swift
//  PawsonaTests
//
//  Regression cover for the weight field losing its value on edit.
//
//  The form formatted the stored weight with a locale-aware FormatStyle but
//  parsed it back with Double(_:), which only understands a dot. In any
//  comma-decimal locale the field showed "12,5", the parse returned nil, and
//  saving wrote that nil over the stored weight — so editing a dog's name
//  silently erased it. Indonesia is the app's primary market.
//

import Foundation
import Testing
@testable import Pawsona

@Suite("Dog weight text")
struct DogDraftWeightTests {
    /// The locales that broke, plus one that never did.
    static let commaDecimalLocales = ["id_ID", "de_DE", "fr_FR"]

    @Test("A weight survives the round-trip the edit form puts it through")
    func weightRoundTripsThroughTheForm() {
        let weight = 12.5
        let shown = DogDraft.weightText(for: weight)

        #expect(DogDraft.weightKg(fromText: shown) == weight)
    }

    @Test("Every fraction the form can show reads back unchanged")
    func everyDisplayableWeightRoundTrips() {
        for tenths in 1...500 {
            let weight = Double(tenths) / 10
            let shown = DogDraft.weightText(for: weight)
            #expect(
                DogDraft.weightKg(fromText: shown) == weight,
                "\(weight) displayed as \"\(shown)\" and did not read back"
            )
        }
    }

    @Test("A comma decimal separator is understood", arguments: commaDecimalLocales)
    func commaSeparatorParses(localeID: String) {
        // Mirrors what the form shows a user in this locale.
        var format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        format.locale = Locale(identifier: localeID)
        let shown = (12.5).formatted(format)

        #expect(shown.contains(","), "expected \(localeID) to use a comma, got \"\(shown)\"")
        #expect(DogDraft.weightKg(fromText: shown) == 12.5)
    }

    @Test("A hand-typed decimal point still works in a comma locale")
    func decimalPointParsesAnywhere() {
        // Someone in Indonesia typing out of habit, or on a keyboard offering a
        // dot, should not have their weight silently dropped either.
        #expect(DogDraft.weightKg(fromText: "12.5") == 12.5)
    }

    @Test("A grouped-looking number is never quietly truncated")
    func groupingIsNotMisread() {
        // Lenient parsing reads "12.5" in id_ID as the integer 12. Storing 12kg
        // for a 12.5kg puppy is a worse failure than refusing the input, so the
        // parse is strict with a plain-decimal fallback.
        let parsed = DogDraft.weightKg(fromText: "12.5")
        #expect(parsed != 12.0)
    }

    @Test("Blank and unreadable text mean no weight, not a crash")
    func emptyAndJunkAreNil() {
        #expect(DogDraft.weightKg(fromText: "") == nil)
        #expect(DogDraft.weightKg(fromText: "   ") == nil)
        #expect(DogDraft.weightKg(fromText: "heavy") == nil)
    }

    @Test("Surrounding whitespace is tolerated")
    func whitespaceIsTrimmed() {
        #expect(DogDraft.weightKg(fromText: "  8  ") == 8)
    }

    @Test("An unset weight shows an empty field")
    func nilWeightShowsNothing() {
        #expect(DogDraft.weightText(for: nil).isEmpty)
    }
}
