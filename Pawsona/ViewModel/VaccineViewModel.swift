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
final class VaccineViewModel{
    var vaccines: [VaccineRecord] = []
    var errorMessage: String?
    // buat variable model context yg bs di panggil dmn2
    func createRecord(
        vaccine: VaccineType,
        dateGiven: Date,
        notes: String?,
        dog: Dog,
        in modelContext: ModelContext
    ){
        let vaccineRecord = VaccineRecord(
            vaccine: vaccine,
            dateGiven: dateGiven,
            notes: notes,
            dog: dog
        )
        
        modelContext.insert(vaccineRecord)
        saveChanges(in: modelContext)
        getAllRecord(in: modelContext)
    }
    
    func getAllRecord(in modelContext: ModelContext){
        let descriptor = FetchDescriptor<VaccineRecord>(
            sortBy: [SortDescriptor(\VaccineRecord.dateGiven)]
        )

        do {
            vaccines = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getRecordById(id: UUID,in modelContext: ModelContext) -> VaccineRecord? {
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
        notes: String?,
        dog: Dog,
        in modelContext: ModelContext
    ){
        vaccineRecord.vaccine = vaccine
        vaccineRecord.dateGiven = dateGiven
        vaccineRecord.notes = notes
        vaccineRecord.dog = dog

        saveChanges(in: modelContext)
        getAllRecord(in: modelContext)
    }
    
    func deleteRecord(id: UUID, in modelContext: ModelContext){
        guard let vaccineRecord = getRecordById(id: id, in: modelContext) else {
            return
        }

        modelContext.delete(vaccineRecord)
        saveChanges(in: modelContext)
        getAllRecord(in: modelContext)
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
