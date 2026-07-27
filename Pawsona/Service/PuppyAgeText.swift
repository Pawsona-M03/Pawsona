import Foundation

enum PuppyAgeText {
    static func value(
        from dateOfBirth: Date?,
        to now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let dateOfBirth else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: dateOfBirth, to: now)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        let ageParts: [String?]
        if years > 0 {
            ageParts = [
                agePart(value: years, singularUnit: "year"),
                agePart(value: months, singularUnit: "month")
            ]
        } else {
            ageParts = [
                agePart(value: months, singularUnit: "month"),
                agePart(value: days, singularUnit: "day")
            ]
        }
        let visibleAgeParts = ageParts.compactMap { $0 }

        return visibleAgeParts.isEmpty
            ? "0 days old"
            : "\(visibleAgeParts.joined(separator: ", ")) old"
    }

    /// The largest unit that is not zero, on its own: "3 years" for a dog that
    /// is 3 years 3 months 24 days, "5 months" at 5 months 12 days, "9 days" for
    /// a new puppy. `value(from:)` spells out two units, which reads well in a
    /// list row but wraps onto a second line in the share card's stat column.
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

        // A puppy born today has nothing above zero, and "0 days" beats an
        // empty stat column.
        let largest = units.first { $0.value > 0 } ?? (value: 0, unit: "day")
        return "\(largest.value) \(largest.value == 1 ? largest.unit : "\(largest.unit)s")"
    }

    private static func agePart(value: Int, singularUnit: String) -> String? {
        guard value > 0 else { return nil }
        let unit = value == 1 ? singularUnit : "\(singularUnit)s"
        return "\(value) \(unit)"
    }
}
