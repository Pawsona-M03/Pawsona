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
    @State private var viewModel = VaccineViewModel()
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingEditVaccineForm = false

    var body: some View {
        NavigationStack {
            List {
                if sortedVaccineRecords.isEmpty {
                    ContentUnavailableView(
                        "No Vaccine Records",
                        systemImage: "syringe",
                        description: Text("Vaccine records you add for your dogs will show up here.")
                    )
                } else {
                    ForEach(sortedVaccineRecords, id: \.id) { vaccineRecord in
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
            .task {
                viewModel.getAllRecord(in: modelContext)
            }
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

    private var sortedVaccineRecords: [VaccineRecord] {
        viewModel.vaccines.sorted { $0.dateGiven > $1.dateGiven }
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
        for index in offsets {
            viewModel.deleteRecord(id: sortedVaccineRecords[index].id, in: modelContext)
        }
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: Dog.self, inMemory: true)
}
