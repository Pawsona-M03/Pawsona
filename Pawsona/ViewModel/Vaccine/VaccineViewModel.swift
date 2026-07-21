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
    func createRecord(from draft: VaccineRecordDraft, in modelContext: ModelContext) -> VaccineRecord {
        let vaccineRecord = VaccineRecord(
            vaccines: draft.vaccines,
            dateGiven: draft.dateGiven,
            notes: draft.notes,
            dogList: draft.dogs
        )

        modelContext.insert(vaccineRecord)
        saveChanges(in: modelContext)
        return vaccineRecord
    }

    func editRecord(
        _ vaccineRecord: VaccineRecord,
        from draft: VaccineRecordDraft,
        in modelContext: ModelContext
    ) {
        vaccineRecord.vaccines = draft.vaccines
        vaccineRecord.dateGiven = draft.dateGiven
        vaccineRecord.notes = draft.notes
        vaccineRecord.dogList = draft.dogs

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
