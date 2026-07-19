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
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingEditVaccineForm = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Vaccination Record")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // Function: open VaccineRecordFormView sheet to add a new record
                        Button("Add Vaccination Record", systemImage: "plus") {
                            isShowingAddVaccineForm = true
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddVaccineForm) {
                    VaccineRecordFormView()
                }
                .sheet(isPresented: $isShowingEditVaccineForm) {
                    if let editingVaccineRecord {
                        VaccineRecordFormView(editing: editingVaccineRecord)
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

    // Function: conditional view -> empty state if vaccineRecords is empty, grouped list if it has content
    @ViewBuilder
    private var content: some View {
        if vaccineRecords.isEmpty {
            emptyState
        } else {
            recordList
        }
    }

    // Function: empty state according to reference (paw pattern background + "Tap '+' to add Vaccination Record")
    private var emptyState: some View {
        ContentUnavailableView(
            "Vaccination Record",
            systemImage: "syringe",
            description: Text("Tap '+' to add Vaccination Record")
        )
    }

    // Function: list of cards, one card = one group (same vaccine + date), contains stacked dog avatars
    private var recordList: some View {
        List {
            // id: first record of each group — group is never empty (result of Dictionary(grouping:))
            ForEach(groupedRecords, id: \.[0].id) { group in
                Button {
                    // ponytail: tap-to-edit gets the first record in the group, edit form
                    // only shows 1 dog. If editing all dogs in a group is needed later,
                    // the form needs to be updated to accept multiple records.
                    editingVaccineRecord = group.first
                    isShowingEditVaccineForm = true
                } label: {
                    VaccineRecordGroupRowView(records: group)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteVaccineRecordGroups)
        }
    }

    // Function: group vaccineRecords by batchID, or fallback to vaccine and dateGiven rounded to minute,
    // so records from 1 submit form (multiple dogs) merge into 1 card
    private var groupedRecords: [[VaccineRecord]] {
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

    private func deleteVaccineRecordGroups(at offsets: IndexSet) {
        let idsToDelete = offsets.flatMap { groupedRecords[$0].map(\.id) }

        for id in idsToDelete {
            viewModel.deleteRecord(id: id, in: modelContext)
        }
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: Dog.self, inMemory: true)
}
