//
//  DogDetailView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dogViewModel = DogViewModel()
    @State private var vaccineViewModel = VaccineViewModel()
    @State private var isShowingEditDogForm = false
    @State private var isShowingAddVaccineForm = false
    @State private var isShowingEditVaccineForm = false
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var exportedPDFURL: URL?
    @State private var exportedDataURL: URL?

    let dog: Dog

    var body: some View {
        List {
            Section {
                DogCardView(dog: dog)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Profile") {
                LabeledContent("Name", value: displayName)
                LabeledContent("Breed", value: dog.breed.isEmpty ? "Not set" : dog.breed)
                LabeledContent("Birthday", value: birthdayText)
            }

            Section {
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
            } header: {
                Text("Vaccine Records")
            } footer: {
                Button("Add Vaccine Record", systemImage: "plus", action: showAddVaccineForm)
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", systemImage: "pencil", action: showEditDogForm)
                    .accessibilityShowsLargeContentViewer()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let exportedDataURL {
                        ShareLink(item: exportedDataURL, preview: SharePreview(displayName)) {
                            Label("Share via AirDrop", systemImage: "wifi")
                        }
                    }

                    if let exportedPDFURL {
                        ShareLink(item: exportedPDFURL, preview: SharePreview(displayName)) {
                            Label("Export as PDF", systemImage: "doc.richtext")
                        }
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(exportedDataURL == nil && exportedPDFURL == nil)
            }
        }
        .sheet(isPresented: $isShowingEditDogForm) {
            DogEditView(dog: dog)
        }
        .sheet(isPresented: $isShowingAddVaccineForm) {
            VaccineRecordFormView(onSave: createVaccineRecord)
        }
        .sheet(isPresented: $isShowingEditVaccineForm) {
            if let vaccineRecord = editingVaccineRecord {
                VaccineRecordFormView(
                    title: "Edit Vaccine Record",
                    vaccine: vaccineRecord.vaccine,
                    dateGiven: vaccineRecord.dateGiven,
                    notes: vaccineRecord.notes ?? "",
                    onSave: { vaccine, dateGiven, notes in
                        editVaccineRecord(vaccineRecord, vaccine: vaccine, dateGiven: dateGiven, notes: notes)
                    }
                )
            }
        }
        .task(id: "\(isShowingEditDogForm)-\(isShowingAddVaccineForm)-\(isShowingEditVaccineForm)") {
            exportedPDFURL = dogViewModel.exportDogToPDF(dog)
            exportedDataURL = dogViewModel.shareDogData(dog)
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var birthdayText: String {
        guard let dateOfBirth = dog.dateOfBirth else {
            return "Not set"
        }

        return dateOfBirth.formatted(date: .long, time: .omitted)
    }

    private var sortedVaccineRecords: [VaccineRecord] {
        (dog.vaccineRecords ?? []).sorted { $0.dateGiven > $1.dateGiven }
    }

    private func showEditDogForm() {
        isShowingEditDogForm = true
    }

    private func showAddVaccineForm() {
        isShowingAddVaccineForm = true
    }

    private func createVaccineRecord(vaccine: VaccineType, dateGiven: Date, notes: String?) {
        vaccineViewModel.createRecord(
            vaccine: vaccine,
            dateGiven: dateGiven,
            notes: notes,
            dog: dog,
            in: modelContext
        )
    }

    private func editVaccineRecord(_ vaccineRecord: VaccineRecord, vaccine: VaccineType, dateGiven: Date, notes: String?) {
        vaccineViewModel.editRecord(
            vaccineRecord,
            vaccine: vaccine,
            dateGiven: dateGiven,
            notes: notes,
            dog: dog,
            in: modelContext
        )
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
        DogDetailView(
            dog: Dog(
                name: "Berry",
                breed: "Labrador Retriever",
                backgroundColor: .green,
                dateOfBirth: Date.now
            )
        )
    }
    .modelContainer(for: Dog.self, inMemory: true)
}
