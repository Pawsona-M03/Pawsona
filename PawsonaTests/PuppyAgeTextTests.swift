import Foundation
import Testing
@testable import Pawsona

@Suite("Puppy age text")
struct PuppyAgeTextTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func birthday(yearsAgo: Int = 0, monthsAgo: Int = 0, daysAgo: Int = 0) -> Date {
        calendar.date(
            byAdding: DateComponents(year: -yearsAgo, month: -monthsAgo, day: -daysAgo),
            to: now
        ) ?? now
    }

    @Test("Years win over the months and days below them")
    func yearsWin() {
        let dateOfBirth = birthday(yearsAgo: 3, monthsAgo: 3, daysAgo: 24)

        #expect(PuppyAgeText.largestUnit(from: dateOfBirth, to: now, calendar: calendar) == "3 years")
    }

    @Test("Months win when there are no whole years")
    func monthsWin() {
        let dateOfBirth = birthday(monthsAgo: 5, daysAgo: 12)

        #expect(PuppyAgeText.largestUnit(from: dateOfBirth, to: now, calendar: calendar) == "5 months")
    }

    @Test("Days are all a new puppy has")
    func daysOnly() {
        let dateOfBirth = birthday(daysAgo: 9)

        #expect(PuppyAgeText.largestUnit(from: dateOfBirth, to: now, calendar: calendar) == "9 days")
    }

    @Test("A puppy born today reads as zero days rather than an empty column")
    func bornToday() {
        #expect(PuppyAgeText.largestUnit(from: now, to: now, calendar: calendar) == "0 days")
    }

    @Test("Singular units drop the s", arguments: [
        (DateComponents(year: -1), "1 year"),
        (DateComponents(month: -1), "1 month"),
        (DateComponents(day: -1), "1 day")
    ])
    func singularUnits(components: DateComponents, expected: String) throws {
        let dateOfBirth = try #require(calendar.date(byAdding: components, to: now))

        #expect(PuppyAgeText.largestUnit(from: dateOfBirth, to: now, calendar: calendar) == expected)
    }

    @Test("No date of birth means no age")
    func noDateOfBirth() {
        #expect(PuppyAgeText.largestUnit(from: nil, to: now, calendar: calendar) == nil)
    }

    /// `value(from:)` is the same selection with "old" on the end — the card
    /// drops the suffix because its column is already labelled "Age". Pinned so
    /// the two cannot drift apart into two implementations again.
    @Test("The app's phrasing is the same age with an \"old\" suffix")
    func appPhrasingAddsSuffix() {
        let dateOfBirth = birthday(yearsAgo: 3, monthsAgo: 3, daysAgo: 24)

        #expect(PuppyAgeText.largestUnit(from: dateOfBirth, to: now, calendar: calendar) == "3 years")
        #expect(PuppyAgeText.value(from: dateOfBirth, to: now, calendar: calendar) == "3 years old")
    }
}
