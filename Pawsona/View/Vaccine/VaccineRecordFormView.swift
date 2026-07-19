//
//  VaccineRecordFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI

/// Form tambah/edit vaccine record: pilih 1 vaccine, tanggal & jam, catatan,
/// dan multi-select puppy. Simpennya lewat VaccineRecordFormViewModel.
struct VaccineRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // @Query: ambil semua dog buat ditampilin di avatar selector
    @Query(sort: \Dog.name) private var dogs: [Dog]

    // @State viewModel: sumber kebenaran field form ini
    @State private var viewModel: VaccineRecordFormViewModel
    @State private var isShowingDeleteConfirmation = false
    private let navigationTitle: String

    // fungsi: init utk TAMBAH record baru
    init() {
        _viewModel = State(initialValue: VaccineRecordFormViewModel())
        navigationTitle = "New Vaccination Record"
    }

    // fungsi: init utk TAMBAH record baru dari konteks 1 dog spesifik (mis. DogDetailView)
    init(preselecting dog: Dog) {
        _viewModel = State(initialValue: VaccineRecordFormViewModel(preselecting: dog))
        navigationTitle = "New Vaccination Record"
    }

    // fungsi: init utk EDIT record yang sudah ada
    init(editing record: VaccineRecord) {
        _viewModel = State(initialValue: VaccineRecordFormViewModel(editing: record))
        navigationTitle = "Edit Vaccination Record"
    }

    // fungsi: batas atas date/time picker -> sekarang, biar nggak bisa input tanggal masa depan
    private var latestAllowedDate: ClosedRange<Date> {
        .distantPast...Date.now
    }

    var body: some View {
        NavigationStack {
            Form {
                vaccineSection
                dateSection
                notesSection

                if !dogs.isEmpty {
                    dogSection
                }

                if viewModel.isEditing {
                    deleteSection
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ToolbarItem X: batal, bentuk bulat sesuai referensi
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .clipShape(.circle)
                }

                // ToolbarItem checkmark: simpan, disabled kalau belum ada dog/vaccine kepilih
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: save)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .tint(Color("VaccineBrown"))
                        .clipShape(.circle)
                        .disabled(!viewModel.isSaveEnabled)
                }
            }
            .confirmationDialog(
                "Delete this vaccination record?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: delete)
            }
        }
    }

    // fungsi: Section pilih vaccine, pakai VaccineSelectionRow (multi-select checkbox)
    private var vaccineSection: some View {
        Section("Vaccine") {
            ForEach(VaccineType.allCases, id: \.self) { vaccine in
                VaccineSelectionRow(vaccine: vaccine, isSelected: viewModel.isVaccineSelected(vaccine)) {
                    viewModel.toggleVaccine(vaccine)
                }
            }
        }
    }

    // fungsi: Section tanggal & jam, dua DatePicker compact sejajar dalam 1 baris,
    // dibatasi sampai sekarang aja (nggak bisa input tanggal/jam di masa depan)
    private var dateSection: some View {
        Section("") {
            HStack {
                Text("Date")
                Spacer()
                HStack {
                    DatePicker(
                        "Date",
                        selection: $viewModel.dateGiven,
                        in: latestAllowedDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()

                    DatePicker(
                        "Time",
                        selection: $viewModel.dateGiven,
                        in: latestAllowedDate,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
        }
    }

    // fungsi: Section pilih dog, avatar bulat berjejer horizontal, multi-select
    private var dogSection: some View {
        Section("Dog") {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(dogs) { dog in
                        DogAvatarSelectionRow(dog: dog, isSelected: viewModel.isSelected(dog)) {
                            viewModel.toggleDog(dog)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // fungsi: Section tombol delete, cuma muncul di mode edit, dibungkus footer biar jelas fungsinya
    private var deleteSection: some View {
        Section {
            Button("Delete Vaccination Record", systemImage: "trash", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func save() {
        viewModel.save(in: modelContext)
        dismiss()
    }

    private func delete() {
        viewModel.delete(in: modelContext)
        dismiss()
    }
}

#Preview {
    VaccineRecordFormView()
        .modelContainer(for: Dog.self, inMemory: true)
}
