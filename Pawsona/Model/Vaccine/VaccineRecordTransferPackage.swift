//
//  VaccineRecordTransferPackage.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import Foundation

/// A `Codable` snapshot of a `VaccineRecord`, used to move vaccine history between devices
/// (e.g. via AirDrop) without exposing SwiftData's `@Model` machinery.
nonisolated struct VaccineRecordTransferPackage: Codable, Sendable {
    var vaccine: VaccineType
    var dateGiven: Date
    var notes: String?

    @MainActor
    init(vaccineRecord: VaccineRecord) {
        vaccine = vaccineRecord.vaccine
        dateGiven = vaccineRecord.dateGiven
        notes = vaccineRecord.notes
    }

    @MainActor
    func makeVaccineRecord(dog: Dog) -> VaccineRecord {
        VaccineRecord(vaccine: vaccine, dateGiven: dateGiven, notes: notes, dog: dog)
    }
}
