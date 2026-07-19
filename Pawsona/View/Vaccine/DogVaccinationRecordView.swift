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
    @State private var isShowingEditVaccineForm = false
    @State private var editingVaccineRecord: VaccineRecord?

    let dog: Dog

    var body: some View {
        List {
            if sortedVaccineRecords.isEmpty {
                ContentUnavailableView(
                    "No Vaccine Records",
                    systemImage: "syringe",
                    description: Text("Add a record to start tracking \(displayName)'s vaccines.")
                )
            } else {
                ForEach(sortedVaccineRecords, id: \.id) { vaccineRecord in
                    Button {
                        editingVaccineRecord = vaccineRecord
                        isShowingEditVaccineForm = true
                    } label: {
                        VaccineRecordRowView(vaccineRecord: vaccineRecord)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteVaccineRecords)
            }
        }
        .navigationTitle("Vaccination Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Vaccine Record", systemImage: "plus", action: showAddVaccineForm)
            }
        }
        .sheet(isPresented: $isShowingAddVaccineForm) {
            VaccineRecordFormView(preselecting: dog)
        }
        .sheet(isPresented: $isShowingEditVaccineForm) {
            if let editingVaccineRecord {
                VaccineRecordFormView(editing: editingVaccineRecord)
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

    private func showAddVaccineForm() {
        isShowingAddVaccineForm = true
    }

    private func deleteVaccineRecords(at offsets: IndexSet) {
        let idsToDelete = offsets.map { sortedVaccineRecords[$0].id }

        Task {
            for id in idsToDelete {
                vaccineViewModel.deleteRecord(id: id, in: modelContext)
            }
        }
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
