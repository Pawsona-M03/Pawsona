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
    @State private var recordPendingDeletion: VaccineRecord?
    @State private var recordPendingContextDeletion: VaccineRecord?

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
                List {
                    ForEach(sortedVaccineRecords, id: \.id) { vaccineRecord in
                        Button {
                            editingVaccineRecord = vaccineRecord
                        } label: {
                            VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: false)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 26, bottom: 8, trailing: 26))
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteSingleVaccineRecord(vaccineRecord)
                            }
                        }
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                recordPendingContextDeletion = vaccineRecord
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                // Restore the 16pt breathing room this screen had above the
                // first card and below the last: 8pt of content margin on top
                // of each row's 8pt inset. Inter-card spacing stays 16pt.
                .contentMargins(.vertical, 8, for: .scrollContent)
            }
        }
        .background(Color(.appBackground).ignoresSafeArea())
        .navigationTitle("Vaccination Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Vaccine Record", systemImage: "plus", action: showAddVaccineForm)
                    .buttonStyle(.glassProminent)
                    .tint(.primaryBrown)
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
        .deleteConfirmation(
            $recordPendingContextDeletion,
            title: "Delete Record?",
            message: { record in
                """
                This removes the \(record.vaccineNames) record from every dog \
                it's assigned to. You can't undo this.
                """
            },
            perform: { record in
                deleteSingleVaccineRecord(record)
            }
        )
        .sheet(item: $editingVaccineRecord, onDismiss: deleteIfRequested) { vaccineRecord in
            VaccineRecordFormView(
                title: "Edit Vaccination Record",
                draft: VaccineRecordDraft(
                    vaccines: vaccineRecord.vaccines,
                    dateGiven: vaccineRecord.dateGiven,
                    dogs: vaccineRecord.dogList ?? [dog],
                    notes: vaccineRecord.notes
                ),
                onDelete: { recordPendingDeletion = vaccineRecord },
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

    /// Runs once the edit sheet is gone. Deleting from inside it would destroy
    /// the record while `sheet(item:)` still holds it, and rebuilding that sheet
    /// re-reads the record's properties to fill the draft.
    private func deleteIfRequested() {
        guard let record = recordPendingDeletion else { return }

        recordPendingDeletion = nil
        deleteSingleVaccineRecord(record)
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
