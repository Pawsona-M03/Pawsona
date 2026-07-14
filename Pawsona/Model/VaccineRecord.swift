//
//  VaccineRecord.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class VaccineRecord {
    var id: UUID = UUID()
    var vaccineTypeRawValue: String = VaccineType.parvovirus.rawValue
    var date: Date = Date.now
    var dog: Dog?

    var vaccineType: VaccineType {
        get {
            VaccineType(rawValue: vaccineTypeRawValue) ?? .parvovirus
        }
        set {
            vaccineTypeRawValue = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        vaccineType: VaccineType = .parvovirus,
        date: Date = Date.now,
        dog: Dog? = nil
    ) {
        self.id = id
        self.vaccineTypeRawValue = vaccineType.rawValue
        self.date = date
        self.dog = dog
    }
}

enum VaccineType: String, Codable, CaseIterable {
    case parvovirus
    case hepatitis
    case distemper
    case leptospira
    case rabies
    case parainfluenza
    case bordetella
}
