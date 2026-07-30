import Foundation

enum PuppyAgeText {
    /// "3 years old" — how the app talks about a puppy's age in list rows and
    /// on the detail screen.
    static func value(
        from dateOfBirth: Date?,
        to now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let largestUnit = largestUnit(from: dateOfBirth, to: now, calendar: calendar) else {
            return nil
        }

        return "\(largestUnit) old"
    }

    /// The same age without the "old" suffix: "3 years", "5 months", "9 days".
    /// The share card labels the column "Age", which makes "old" redundant and
    /// costs width the stat column does not have.
    ///
    /// Only the largest unit that is not zero — a dog of 3 years 3 months 24
    /// days is "3 years", not a list of all three.
    static func largestUnit(
        from dateOfBirth: Date?,
        to now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let dateOfBirth else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: dateOfBirth, to: now)
        let units = [
            (value: components.year ?? 0, unit: "year"),
            (value: components.month ?? 0, unit: "month"),
            (value: components.day ?? 0, unit: "day")
        ]

        // A puppy born today has nothing above zero, and "0 days" beats a blank.
        let largest = units.first { $0.value > 0 } ?? (value: 0, unit: "day")
        return agePart(value: largest.value, singularUnit: largest.unit)
    }

    private static func agePart(value: Int, singularUnit: String) -> String {
        let unit = value == 1 ? singularUnit : "\(singularUnit)s"
        return "\(value) \(unit)"
    }
}
