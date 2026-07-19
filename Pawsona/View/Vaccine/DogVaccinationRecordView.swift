//
//  DogVaccinationRecordView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftData
import SwiftUI

struct DogVaccinationRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vaccineViewModel = VaccineViewModel()
    @State private var isShowingAddVaccineForm = false

    let dog: Dog

    var body: some View {
        let currentRecords = sortedVaccineRecords

        VaccineRecordListScaffold(
            data: currentRecords,
            emptyTitle: "No Vaccine Records",
            emptyDescription: "Add a record to start tracking \(displayName)'s vaccines.",
            isShowingAddVaccineForm: $isShowingAddVaccineForm,
            recordToEdit: { $0 },
            onDelete: { offsets in
                let idsToDelete = offsets.map { currentRecords[$0].id }
                for id in idsToDelete {
                    vaccineViewModel.deleteRecord(id: id, in: modelContext)
                }
            },
            rowContent: { vaccineRecord in
                VaccineRecordRowView(vaccineRecord: vaccineRecord)
            },
            addFormContent: {
                VaccineRecordFormView(preselecting: dog)
            }
        )
        .navigationTitle("Vaccination Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Vaccine Record", systemImage: "plus") {
                    isShowingAddVaccineForm = true
                }
            }
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var sortedVaccineRecords: [VaccineRecord] {
        (dog.vaccineRecords ?? []).sorted { $0.dateGiven > $1.dateGiven }
    }
}

#Preview {
    NavigationStack {
        DogVaccinationRecordView(
            dog: Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green)
        )
    }
    .modelContainer(for: Dog.self, inMemory: true)
}
