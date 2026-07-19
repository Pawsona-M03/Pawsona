//
//  VaccineListView.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftData
import SwiftUI

struct VaccineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VaccineRecord.dateGiven, order: .reverse) private var vaccineRecords: [VaccineRecord]
    @State private var viewModel = VaccineViewModel()

    @State private var isShowingAddVaccineForm = false

    var body: some View {
        let currentGroups = computeGroupedRecords()

        NavigationStack {
            VaccineRecordListScaffold(
                data: currentGroups,
                id: \.[0].id,
                emptyTitle: "Vaccination Record",
                emptyDescription: "Tap '+' to add Vaccination Record",
                isShowingAddVaccineForm: $isShowingAddVaccineForm,
                recordToEdit: { $0.first },
                onDelete: { offsets in
                    let idsToDelete = offsets.flatMap { currentGroups[$0].map(\.id) }
                    for id in idsToDelete {
                        viewModel.deleteRecord(id: id, in: modelContext)
                    }
                },
                rowContent: { group in
                    VaccineRecordGroupRowView(records: group)
                },
                addFormContent: {
                    VaccineRecordFormView()
                }
            )
            .navigationTitle("Vaccination Record")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Function: open VaccineRecordFormView sheet to add a new record
                    Button("Add Vaccination Record", systemImage: "plus") {
                        isShowingAddVaccineForm = true
                    }
                }
            }
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) { }
                },
                message: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    }
                }
            )
        }
    }

    // Function: group vaccineRecords by batchID, or fallback to vaccine and dateGiven rounded to minute,
    // so records from 1 submit form (multiple dogs) merge into 1 card
    private func computeGroupedRecords() -> [[VaccineRecord]] {
        let groups = Dictionary(grouping: vaccineRecords, by: groupKey)
        return groups.values.sorted { lhs, rhs in
            (lhs.first?.dateGiven ?? .distantPast) > (rhs.first?.dateGiven ?? .distantPast)
        }
    }

    private func groupKey(for record: VaccineRecord) -> String {
        if let batchID = record.batchID {
            return "batch-\(batchID.uuidString)"
        }
        let roundedMinute = Int(record.dateGiven.timeIntervalSinceReferenceDate / 60)
        return "legacy-\(record.vaccine.rawValue)-\(roundedMinute)"
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: Dog.self, inMemory: true)
}
