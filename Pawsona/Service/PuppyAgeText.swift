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

        if years > 0 {
            return "\(agePart(value: years, singularUnit: "year")) old"
        }

        if months > 0 {
            return "\(agePart(value: months, singularUnit: "month")) old"
        }

        if days > 0 {
            return "\(agePart(value: days, singularUnit: "day")) old"
        }

        return "0 days old"
    }

    private static func agePart(value: Int, singularUnit: String) -> String {
        let unit = value == 1 ? singularUnit : "\(singularUnit)s"
        return "\(value) \(unit)"
    }
}
