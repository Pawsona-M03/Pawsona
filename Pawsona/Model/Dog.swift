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
    var dateOfBirth: Date?
    var weight: Double?
    var sex: Sex?
    @Attribute(.externalStorage) var photoData: Data?
    var reminders: [Reminder]? = nil
    var vaccineRecords: [VaccineRecord]? = nil

    var age: Int? {
        guard let dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year
    }

    init(
        id: UUID = UUID(),
        name: String? = nil,
        breed: String = "",
        backgroundColor: ColorType = .gray,
        dateOfBirth: Date? = nil,
        weight: Double? = nil,
        sex: Sex? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.backgroundColor = backgroundColor
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.sex = sex
        self.photoData = photoData
    }
}
