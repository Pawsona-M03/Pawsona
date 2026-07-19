//
//  VaccineViewModel.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import Foundation
import Observation
import SwiftData

@Observable
final class VaccineViewModel {
    var errorMessage: String?
    // Create a model context variable that can be used anywhere
    func createRecords(
        vaccines: [VaccineType],
        dateGiven: Date,
        notes: String?,
        dogs: [Dog],
        in modelContext: ModelContext
    ) {
        let batchID = UUID()
        for dog in dogs {
            for vaccine in vaccines {
                let vaccineRecord = VaccineRecord(
                    batchID: batchID,
                    vaccine: vaccine,
                    dateGiven: dateGiven,
                    notes: notes,
                    dog: dog
                )
                modelContext.insert(vaccineRecord)
            }
        }
        saveChanges(in: modelContext)
    }

    func getRecordById(id: UUID, in modelContext: ModelContext) -> VaccineRecord? {
        let descriptor = FetchDescriptor<VaccineRecord>(
            predicate: #Predicate { vaccine in
                vaccine.id == id
            }
        )
        do {
            errorMessage = nil
            return try modelContext.fetch(descriptor).first
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func editRecord(
        _ vaccineRecord: VaccineRecord,
        vaccine: VaccineType,
        dateGiven: Date,
        notes: String? = nil,
        dog: Dog,
        in modelContext: ModelContext
    ) {
        vaccineRecord.vaccine = vaccine
        vaccineRecord.dateGiven = dateGiven
        vaccineRecord.notes = notes
        vaccineRecord.dog = dog

        saveChanges(in: modelContext)
    }

    func deleteRecord(id: UUID, in modelContext: ModelContext) {
        guard let vaccineRecord = getRecordById(id: id, in: modelContext) else {
            return
        }

        modelContext.delete(vaccineRecord)
        saveChanges(in: modelContext)
    }

    private func saveChanges(in modelContext: ModelContext) {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
