//
//  VaccineRecordTransferPackage.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import Foundation

/// A `Codable` snapshot of a `VaccineRecord`, used to move vaccine history between devices
/// (e.g. via AirDrop) without exposing SwiftData's `@Model` machinery.
struct VaccineRecordTransferPackage: Codable {
    var vaccines: [VaccineType]
    var dateGiven: Date
    var notes: String?

    init(vaccineRecord: VaccineRecord) {
        vaccines = vaccineRecord.vaccines
        dateGiven = vaccineRecord.dateGiven
        notes = vaccineRecord.notes
    }

    func makeVaccineRecord(dog: Dog) -> VaccineRecord {
        VaccineRecord(vaccines: vaccines, dateGiven: dateGiven, notes: notes, dogList: [dog])
    }
}
