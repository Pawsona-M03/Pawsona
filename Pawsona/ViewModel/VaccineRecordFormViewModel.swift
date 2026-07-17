//
//  VaccineRecordFormViewModel.swift
//  Pawsona
//

import Foundation
import Observation
import SwiftData

/// Backs the add/edit vaccine record form: nyimpen field yang lagi diisi user,
/// nge-gate tombol save, dan nyimpen record-nya (bisa ke beberapa dog sekaligus).
@Observable
final class VaccineRecordFormViewModel {
    var selectedVaccines: [VaccineType]
    var dateGiven: Date
    var notes: String
    var selectedDogs: [Dog]
    var errorMessage: String?

    private let editingRecord: VaccineRecord?
    private let vaccineViewModel: VaccineViewModel

    // fungsi: init buat record BARU, belum ada vaccine/dog kepilih
    init(vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = []
        self.dateGiven = .now
        self.notes = ""
        self.selectedDogs = []
        self.editingRecord = nil
        self.vaccineViewModel = vaccineViewModel
    }

    // fungsi: init buat record BARU dari konteks 1 dog spesifik (mis. DogDetailView) —
    // dog-nya udah kepilih duluan, user tetap bisa nambah dog lain di avatar selector
    init(preselecting dog: Dog, vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = []
        self.dateGiven = .now
        self.notes = ""
        self.selectedDogs = [dog]
        self.editingRecord = nil
        self.vaccineViewModel = vaccineViewModel
    }

    // fungsi: init buat EDIT record yang udah ada, isi field dari data lama
    init(editing record: VaccineRecord, vaccineViewModel: VaccineViewModel = VaccineViewModel()) {
        self.selectedVaccines = [record.vaccine]
        self.dateGiven = record.dateGiven
        self.notes = record.notes ?? ""
        self.selectedDogs = record.dog.map { [$0] } ?? []
        self.editingRecord = record
        self.vaccineViewModel = vaccineViewModel
    }

    // fungsi: form ini lagi mode edit (bukan bikin baru) -> dipake buat nampilin tombol delete
    var isEditing: Bool {
        editingRecord != nil
    }

    // fungsi: tombol Save aktif kalau minimal 1 dog & 1 vaccine kepilih
    var isSaveEnabled: Bool {
        !selectedDogs.isEmpty && !selectedVaccines.isEmpty
    }

    // fungsi: tambah/hapus dog dari daftar terpilih (dipanggil dari DogAvatarSelectionRow)
    func toggleDog(_ dog: Dog) {
        if let index = selectedDogs.firstIndex(where: { $0.id == dog.id }) {
            selectedDogs.remove(at: index)
        } else {
            selectedDogs.append(dog)
        }
    }

    // fungsi: dicek DogAvatarSelectionRow buat nentuin ring seleksi nyala atau enggak
    func isSelected(_ dog: Dog) -> Bool {
        selectedDogs.contains { $0.id == dog.id }
    }

    // fungsi: tambah/hapus vaccine dari daftar terpilih (dipanggil dari VaccineSelectionRow)
    func toggleVaccine(_ vaccine: VaccineType) {
        if let index = selectedVaccines.firstIndex(of: vaccine) {
            selectedVaccines.remove(at: index)
        } else {
            selectedVaccines.append(vaccine)
        }
    }

    // fungsi: dicek VaccineSelectionRow buat nentuin checkbox nyala atau enggak
    func isVaccineSelected(_ vaccine: VaccineType) -> Bool {
        selectedVaccines.contains(vaccine)
    }

    // fungsi: simpen. Kalau lagi edit -> update 1 record (ambil dog & vaccine pertama).
    // Kalau baru -> loop createRecord per kombinasi dog x vaccine yang kepilih
    // (VaccineRecord.dog dan .vaccine itu 1-ke-1, jadi tiap kombinasi jadi record sendiri).
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
            for dog in selectedDogs {
                for vaccine in selectedVaccines {
                    vaccineViewModel.createRecord(
                        vaccine: vaccine,
                        dateGiven: dateGiven,
                        notes: noteValue,
                        dog: dog,
                        in: modelContext
                    )
                }
            }
        }

        errorMessage = vaccineViewModel.errorMessage
    }

    // fungsi: hapus record yang lagi diedit (dipanggil dari tombol delete di form)
    func delete(in modelContext: ModelContext) {
        guard let editingRecord else { return }
        vaccineViewModel.deleteRecord(id: editingRecord.id, in: modelContext)
        errorMessage = vaccineViewModel.errorMessage
    }
}
