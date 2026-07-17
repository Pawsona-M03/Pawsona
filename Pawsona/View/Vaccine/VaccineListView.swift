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
    @State private var isShowingNewVaccineForm = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading, spacing: 24) {
                    if vaccineRecords.isEmpty {
                        Spacer()

                        Text("Tap '+' to add Vaccination Record")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                                    Button {
                                        editingVaccineRecord = vaccineRecord
                                    } label: {
                                        VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 26)
            }
            .navigationTitle("Vaccination Record")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Vaccination Record", systemImage: "plus", action: showNewVaccineForm)
                        .tint(.brown)
                        .accessibilityShowsLargeContentViewer()
                }
            }
            .sheet(isPresented: $isShowingNewVaccineForm) {
                VaccineRecordFormView(
                    title: "New Vaccination Record",
                    onSave: createVaccineRecord
                )
            }
            .sheet(item: $editingVaccineRecord) { vaccineRecord in
                VaccineRecordFormView(
                    title: "Edit Vaccination Record",
                    vaccines: vaccineRecord.vaccines,
                    dateGiven: vaccineRecord.dateGiven,
                    selectedDogs: vaccineRecord.dogList ?? [],
                    notes: vaccineRecord.notes ?? "",
                    onSave: { vaccines, dateGiven, dogList, notes in
                        editVaccineRecord(
                            vaccineRecord,
                            dogList: dogList,
                            vaccines: vaccines,
                            dateGiven: dateGiven,
                            notes: notes
                        )
                    }
                )
            }
        }
    }

    private func showNewVaccineForm() {
        isShowingNewVaccineForm = true
    }

    private func createVaccineRecord(vaccines: [VaccineType], dateGiven: Date, dogList: [Dog], notes: String?) {
        viewModel.createRecord(
            vaccines: vaccines,
            dateGiven: dateGiven,
            notes: notes,
            dogList: dogList,
            in: modelContext
        )
    }

    private func editVaccineRecord(
        _ vaccineRecord: VaccineRecord,
        dogList: [Dog],
        vaccines: [VaccineType],
        dateGiven: Date,
        notes: String?
    ) {
        viewModel.editRecord(
            vaccineRecord,
            vaccines: vaccines,
            dateGiven: dateGiven,
            notes: notes,
            dogList: dogList,
            in: modelContext
        )
    }
}

private struct PawPrintBackground: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 28), count: 4)

    var body: some View {
        Color(.systemBackground)
            .overlay {
                LazyVGrid(columns: columns, spacing: 34) {
                    ForEach(0..<56, id: \.self) { index in
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: index.isMultiple(of: 3) ? 32 : 26))
                            .foregroundStyle(.secondary.opacity(0.12))
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -18 : 16))
                    }
                }
                .padding(18)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}
