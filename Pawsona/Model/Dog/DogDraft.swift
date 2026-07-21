//
//  DogDraft.swift
//  Pawsona
//

import Foundation

/// Editable form values for creating or updating a `Dog`, passed between
/// `DogFormView` and `DogViewModel` so neither needs a long parameter list.
struct DogDraft {
    var name = ""
    var breed = ""
    var dateOfBirth = Date.now
    var backgroundColor = ColorType.blue
    var weightKg: Double?
    var sex: Sex?
    var photoData: Data?
}

// MARK: - Weight text

/// Formatting and parsing for the weight field, kept together deliberately.
///
/// These were previously split across `DogFormView` — formatted with a
/// locale-aware `FormatStyle`, parsed back with `Double(_:)`, which only ever
/// understands a dot. In any comma-decimal locale (`id_ID`, `de_DE`, …) the
/// field showed "12,5", the parse returned nil, and saving wrote that nil
/// straight over the stored weight. Editing a dog's name silently erased it.
extension DogDraft {
    /// How a stored weight is shown in the form. Empty for an unset weight.
    static func weightText(for weightKg: Double?) -> String {
        weightKg?.formatted(weightFormat) ?? ""
    }

    /// Reads the weight field back, or nil when it is empty or unreadable.
    ///
    /// Tries the user's locale first, then a plain decimal point, so both
    /// "12,5" and a hand-typed "12.5" work for someone in Indonesia. Parsing is
    /// deliberately **strict**: lenient parsing reads "12.5" in `id_ID` as the
    /// grouped integer 12, which is a quieter and worse failure than nil.
    static func weightKg(fromText text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let localised = try? Double(trimmed, format: weightFormat, lenient: false) {
            return localised
        }

        return Double(trimmed)
    }

    private static let weightFormat = FloatingPointFormatStyle<Double>.number
        .precision(.fractionLength(0...1))
}
