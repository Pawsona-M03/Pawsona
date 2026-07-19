//
//  VaccineRecordFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

struct VaccineRecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (VaccineType, Date, String?) -> Void

    @State private var vaccine: VaccineType
    @State private var dateGiven: Date
    @State private var notes: String

    init(
        title: String = "Add Vaccine Record",
        vaccine: VaccineType = .parvovirus,
        dateGiven: Date = Date.now,
        notes: String = "",
        onSave: @escaping (VaccineType, Date, String?) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._vaccine = State(initialValue: vaccine)
        self._dateGiven = State(initialValue: dateGiven)
        self._notes = State(initialValue: notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vaccine") {
                    Picker("Vaccine", selection: $vaccine) {
                        ForEach(VaccineType.allCases, id: \.self) { vaccine in
                            Text(vaccine.displayName)
                                .tag(vaccine)
                        }
                    }

                    DatePicker(
                        "Date Given",
                        selection: $dateGiven,
                        displayedComponents: .date
                    )
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveVaccineRecord)
                }
            }
        }
    }

    private func saveVaccineRecord() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(vaccine, dateGiven, trimmedNotes.isEmpty ? nil : trimmedNotes)
        dismiss()
    }
}

#Preview {
    VaccineRecordFormView { _, _, _ in }
}
