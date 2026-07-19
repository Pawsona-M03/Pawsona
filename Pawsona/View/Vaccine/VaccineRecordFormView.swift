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
                VaccineRecordFormVaccineSection(viewModel: viewModel)
                VaccineRecordFormDateSection(viewModel: viewModel)
                VaccineRecordFormNotesSection(viewModel: viewModel)

                if !dogs.isEmpty {
                    VaccineRecordFormDogSection(viewModel: viewModel, dogs: dogs)
                }

                if viewModel.isEditing {
                    VaccineRecordFormDeleteSection(isShowingDeleteConfirmation: $isShowingDeleteConfirmation)
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
