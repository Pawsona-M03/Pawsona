//
//  VaccineRecordFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI

/// Add/edit vaccine record form: select 1 vaccine, date & time, notes,
/// and multi-select puppy. Saved via VaccineRecordFormViewModel.
struct VaccineRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // @Query: fetch all dogs to display in the avatar selector
    @Query(sort: \Dog.name) private var dogs: [Dog]

    // @State viewModel: source of truth for this form's fields
    @State private var viewModel: VaccineRecordFormViewModel
    @State private var isShowingDeleteConfirmation = false
    private let navigationTitle: String

    // Function: Init for ADDING a new record
    init() {
        _viewModel = State(initialValue: VaccineRecordFormViewModel())
        navigationTitle = "New Vaccination Record"
    }

    // Function: Init for ADDING a new record from a specific dog context (e.g. DogDetailView)
    init(preselecting dog: Dog) {
        _viewModel = State(initialValue: VaccineRecordFormViewModel(preselecting: dog))
        navigationTitle = "New Vaccination Record"
    }

    // Function: Init for EDITING an existing record
    init(editing record: VaccineRecord) {
        _viewModel = State(initialValue: VaccineRecordFormViewModel(editing: record))
        navigationTitle = "Edit Vaccination Record"
    }

    // Function: Upper limit for date/time picker -> now, to prevent inputting future dates
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
                // ToolbarItem X: cancel, rounded shape according to reference
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .clipShape(.circle)
                }

                // ToolbarItem checkmark: save, disabled if no dog/vaccine is selected
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: save)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.vaccineBrown))
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

    // Function: Section to select vaccine, using VaccineSelectionRow (multi-select checkbox)
    private var vaccineSection: some View {
        Section("Vaccine") {
            ForEach(VaccineType.allCases, id: \.self) { vaccine in
                VaccineSelectionRow(vaccine: vaccine, isSelected: viewModel.isVaccineSelected(vaccine)) {
                    viewModel.toggleVaccine(vaccine)
                }
            }
        }
    }

    // Function: Date & time section, single DatePicker limited to now
    private var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                DatePicker(
                    "Date",
                    selection: $viewModel.dateGiven,
                    in: latestAllowedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
        }
    }

    // Function: Section to select dog, horizontal rounded avatars, multi-select
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

    // Function: Section for delete button, only shown in edit mode, wrapped in footer for clarity
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
