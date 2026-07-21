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
        Group {
            if sortedVaccineRecords.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        "No Vaccine Records",
                        systemImage: "syringe",
                        description: Text("Add a record to start tracking \(dog.displayName)'s vaccines.")
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sortedVaccineRecords, id: \.id) { vaccineRecord in
                            Button {
                                editingVaccineRecord = vaccineRecord
                            } label: {
                                VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: false)
                            }
                            .buttonStyle(.plain)
                            // Long-press to delete.
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSingleVaccineRecord(vaccineRecord)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 26)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(Color(.appBackground).ignoresSafeArea())
        .navigationTitle("Vaccination Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Vaccine Record", systemImage: "plus", action: showAddVaccineForm)
            }
        }
        .sheet(isPresented: $isShowingAddVaccineForm) {
            VaccineRecordFormView(
                draft: VaccineRecordDraft(dogs: [dog]),
                onSave: createVaccineRecord
            )
        }
        .alert("Something went wrong", isPresented: $vaccineViewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vaccineViewModel.errorMessage ?? "")
        }
        .sheet(item: $editingVaccineRecord) { vaccineRecord in
            VaccineRecordFormView(
                title: "Edit Vaccine Record",
                draft: VaccineRecordDraft(
                    vaccines: vaccineRecord.vaccines,
                    dateGiven: vaccineRecord.dateGiven,
                    dogs: vaccineRecord.dogList ?? [dog],
                    notes: vaccineRecord.notes
                ),
                onSave: { draft in
                    vaccineViewModel.editRecord(vaccineRecord, from: draft, in: modelContext)
                }
            )
        }
    }

    private var sortedVaccineRecords: [VaccineRecord] {
        (dog.vaccineRecords ?? []).sorted { $0.dateGiven > $1.dateGiven }
    }

    private func showAddVaccineForm() {
        isShowingAddVaccineForm = true
    }

    private func createVaccineRecord(_ draft: VaccineRecordDraft) {
        vaccineViewModel.createRecord(from: draft, in: modelContext)
    }

    private func deleteSingleVaccineRecord(_ record: VaccineRecord) {
        vaccineViewModel.deleteRecord(record, in: modelContext)
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
