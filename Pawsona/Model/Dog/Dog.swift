//
//  Dog.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class Dog {
    var id: UUID = UUID()
    var name: String?
    var breed: String = ""
    var backgroundColor: ColorType = ColorType.gray
    var createdAt: Date = Date.now
    var dateOfBirth: Date?
    var weight: Double?
    var sex: Sex?
    @Attribute(.externalStorage) var photoData: Data?
    var reminders: [Reminder]?
    var vaccineRecords: [VaccineRecord]?

    var age: Int? {
        guard let dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year
    }

    /// What to call this dog on screen. `name` is optional and may be blank, and
    /// six views used to each decide their own fallback — which had already
    /// drifted, so the same dog read as "Dog" on one screen and "Puppy" on the
    /// next. "Puppy" wins because it matches the generated "Puppy 1" names.
    var displayName: String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Puppy" : trimmedName
    }

    /// Breed for display, with a placeholder when it was never filled in.
    var breedText: String {
        breed.isEmpty ? "Breed not set" : breed
    }

    /// "1 year, 2 months old", or nil when the date of birth is unknown.
    var ageText: String? {
        Self.ageText(from: dateOfBirth)
    }

    static func ageText(
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

        if visibleAgeParts.isEmpty {
            return "0 days old"
        }

        return "\(visibleAgeParts.joined(separator: ", ")) old"
    }

    private static func agePart(value: Int, singularUnit: String) -> String? {
        guard value > 0 else { return nil }
        let unit = value == 1 ? singularUnit : "\(singularUnit)s"
        return "\(value) \(unit)"
    }

    init(
        id: UUID = UUID(),
        name: String? = nil,
        breed: String = "",
        backgroundColor: ColorType = .gray,
        createdAt: Date = .now,
        dateOfBirth: Date? = nil,
        weight: Double? = nil,
        sex: Sex? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.backgroundColor = backgroundColor
        self.createdAt = createdAt
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.sex = sex
        self.photoData = photoData
    }
}
