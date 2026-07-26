import Foundation

enum MarketplacePhoneNumber {
    static func normalize(_ input: String, defaultCountryCode: String = "62") throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedSeparators = CharacterSet(charactersIn: " -().")
        let compact = trimmed.unicodeScalars
            .filter { !allowedSeparators.contains($0) }
            .map(String.init)
            .joined()

        guard !compact.isEmpty else {
            throw MarketplaceError.invalidPhoneNumber
        }

        let internationalDigits: String
        if compact.hasPrefix("+") {
            internationalDigits = String(compact.dropFirst())
        } else if compact.hasPrefix("0") {
            internationalDigits = defaultCountryCode + compact.dropFirst()
        } else if compact.hasPrefix(defaultCountryCode) {
            internationalDigits = compact
        } else {
            throw MarketplaceError.invalidPhoneNumber
        }

        guard internationalDigits.allSatisfy(\.isNumber),
              (8...15).contains(internationalDigits.count),
              internationalDigits.first != "0" else {
            throw MarketplaceError.invalidPhoneNumber
        }

        return "+\(internationalDigits)"
    }

    static func digitsOnly(_ normalizedNumber: String) throws -> String {
        let normalized = try normalize(normalizedNumber)
        return String(normalized.dropFirst())
    }
}
