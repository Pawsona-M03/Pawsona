//
//  VaccineRecordFormViewModel.swift
//  Pawsona
//

import Foundation
import Observation
import SwiftData

/// Backs the add/edit vaccine record form: stores user input,
/// gates the save button, and saves records (can be to multiple dogs at once).
@Observable
final class VaccineRecordFormViewModel {
    var selectedVaccines: [VaccineType]
    var dateGiven: Date
    var notes: String
    var selectedDogs: [Dog]
    var errorMessage: String?

    private let editingRecord: VaccineRecord?
    private let vaccineViewModel: VaccineViewModel

    // Function: Init for a NEW record, no vaccine/dog selected yet
    init(vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = []
        self.dateGiven = .now
        self.notes = ""
        self.selectedDogs = []
        self.editingRecord = nil
        self.vaccineViewModel = vaccineViewModel
    }

    // Function: Init for a NEW record from a specific dog context (e.g. DogDetailView) —
    // dog is preselected, user can still add other dogs in the avatar selector
    init(preselecting dog: Dog, vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = []
        self.dateGiven = .now
        self.notes = ""
        self.selectedDogs = [dog]
        self.editingRecord = nil
        self.vaccineViewModel = vaccineViewModel
    }

    // Function: Init for EDITING an existing record, fills fields from old data
    init(editing record: VaccineRecord, vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = [record.vaccine]
        self.dateGiven = record.dateGiven
        self.notes = record.notes ?? ""
        self.selectedDogs = record.dog.map { [$0] } ?? []
        self.editingRecord = record
        self.vaccineViewModel = vaccineViewModel
    }

    // Function: Form is in edit mode (not creating new) -> used to show delete button
    var isEditing: Bool {
        editingRecord != nil
    }

    // Function: Save button is active if at least 1 dog and 1 vaccine are selected
    var isSaveEnabled: Bool {
        !selectedDogs.isEmpty && !selectedVaccines.isEmpty
    }

    // Function: Add/remove dog from selection (called from DogAvatarSelectionRow)
    func toggleDog(_ dog: Dog) {
        if isEditing {
            selectedDogs = [dog]
        } else {
            if let index = selectedDogs.firstIndex(where: { $0.id == dog.id }) {
                selectedDogs.remove(at: index)
            } else {
                selectedDogs.append(dog)
            }
        }
    }

    // Function: Checked by DogAvatarSelectionRow to determine if selection ring is active
    func isSelected(_ dog: Dog) -> Bool {
        selectedDogs.contains { $0.id == dog.id }
    }

    // Function: Add/remove vaccine from selection (called from VaccineSelectionRow)
    func toggleVaccine(_ vaccine: VaccineType) {
        if isEditing {
            selectedVaccines = [vaccine]
        } else {
            if let index = selectedVaccines.firstIndex(of: vaccine) {
                selectedVaccines.remove(at: index)
            } else {
                selectedVaccines.append(vaccine)
            }
        }
    }

    // Function: Checked by VaccineSelectionRow to determine if checkbox is active
    func isVaccineSelected(_ vaccine: VaccineType) -> Bool {
        selectedVaccines.contains(vaccine)
    }

    // Function: Save. If editing -> update 1 record (take first dog & vaccine).
    // If new -> bulk create records per selected dog and vaccine combination.
    func save(in modelContext: ModelContext) {
        guard isSaveEnabled else { return }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let editingRecord, let dog = selectedDogs.first, let vaccine = selectedVaccines.first {
            vaccineViewModel.editRecord(
                editingRecord,
                vaccine: vaccine,
                dateGiven: dateGiven,
                notes: noteValue,
                dog: dog,
                in: modelContext
            )
        } else {
            vaccineViewModel.createRecords(
                vaccines: selectedVaccines,
                dateGiven: dateGiven,
                notes: noteValue,
                dogs: selectedDogs,
                in: modelContext
            )
        }

        errorMessage = vaccineViewModel.errorMessage
    }

    // Function: Delete the record being edited (called from delete button in form)
    func delete(in modelContext: ModelContext) {
        guard let editingRecord else { return }
        vaccineViewModel.deleteRecord(id: editingRecord.id, in: modelContext)
        errorMessage = vaccineViewModel.errorMessage
    }
}
