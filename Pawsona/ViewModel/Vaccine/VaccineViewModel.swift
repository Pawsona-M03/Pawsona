//
//  VaccineViewModel.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import Foundation
import Observation
import SwiftData

/// Writes for vaccine records. Like `DogViewModel` this holds no record array:
/// both screens that use it read through `@Query` or the dog's own
/// relationship, so a cached copy here would only be a second, staler truth.
@Observable
final class VaccineViewModel {
    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    @discardableResult
    func createRecord(
        vaccines: [VaccineType],
        dateGiven: Date,
        notes: String?,
        dogList: [Dog],
        in modelContext: ModelContext
    ) -> VaccineRecord {
        let vaccineRecord = VaccineRecord(
            vaccines: vaccines,
            dateGiven: dateGiven,
            notes: notes,
            dogList: dogList
        )

        modelContext.insert(vaccineRecord)
        saveChanges(in: modelContext)
        return vaccineRecord
    }

    func editRecord(
        _ vaccineRecord: VaccineRecord,
        vaccines: [VaccineType],
        dateGiven: Date,
        notes: String?,
        dogList: [Dog],
        in modelContext: ModelContext
    ) {
        vaccineRecord.vaccines = vaccines
        vaccineRecord.dateGiven = dateGiven
        vaccineRecord.notes = notes
        vaccineRecord.dogList = dogList

        saveChanges(in: modelContext)
    }

    func deleteRecord(_ vaccineRecord: VaccineRecord, in modelContext: ModelContext) {
        modelContext.delete(vaccineRecord)
        saveChanges(in: modelContext)
    }

    private func saveChanges(in modelContext: ModelContext) {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "That change couldn't be saved. Try again."
        }
    }
}
