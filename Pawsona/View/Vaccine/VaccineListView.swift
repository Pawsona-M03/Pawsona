//
//  VaccineListView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI

struct VaccineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VaccineRecord.dateGiven, order: .reverse) private var vaccineRecords: [VaccineRecord]
    @State private var viewModel = VaccineViewModel()
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingEditVaccineForm = false

    var body: some View {
        NavigationStack {
            List {
                if vaccineRecords.isEmpty {
                    ContentUnavailableView(
                        "No Vaccine Records",
                        systemImage: "syringe",
                        description: Text("Vaccine records you add for your dogs will show up here.")
                    )
                } else {
                    ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                        Button {
                            editingVaccineRecord = vaccineRecord
                            isShowingEditVaccineForm = true
                        } label: {
                            VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: true)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteVaccineRecords)
                }
            }
            .navigationTitle("Vaccines")
            .sheet(isPresented: $isShowingEditVaccineForm) {
                if let vaccineRecord = editingVaccineRecord, let dog = vaccineRecord.dog {
                    VaccineRecordFormView(
                        title: "Edit Vaccine Record",
                        vaccine: vaccineRecord.vaccine,
                        dateGiven: vaccineRecord.dateGiven,
                        notes: vaccineRecord.notes ?? "",
                        onSave: { vaccine, dateGiven, notes in
                            editVaccineRecord(vaccineRecord, dog: dog, vaccine: vaccine, dateGiven: dateGiven, notes: notes)
                        }
                    )
                }
            }
        }
    }

    private func editVaccineRecord(
        _ vaccineRecord: VaccineRecord,
        dog: Dog,
        vaccine: VaccineType,
        dateGiven: Date,
        notes: String?
    ) {
        viewModel.editRecord(
            vaccineRecord,
            vaccine: vaccine,
            dateGiven: dateGiven,
            notes: notes,
            dog: dog,
            in: modelContext
        )
    }

    private func deleteVaccineRecords(at offsets: IndexSet) {
        let idsToDelete = offsets.map { vaccineRecords[$0].id }

        Task {
            for id in idsToDelete {
                viewModel.deleteRecord(id: id, in: modelContext)
            }
        }
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: Dog.self, inMemory: true)
}
