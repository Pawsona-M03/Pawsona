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

    private static func agePart(value: Int, singularUnit: String) -> String? {
        guard value > 0 else { return nil }
        let unit = value == 1 ? singularUnit : "\(singularUnit)s"
        return "\(value) \(unit)"
    }
}
