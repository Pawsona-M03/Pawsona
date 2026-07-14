//
//  DogFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

struct DogFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (String, String, Date, ColorType) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var dateOfBirth: Date
    @State private var backgroundColor: ColorType

    init(
        title: String = "Add Dog",
        name: String = "",
        breed: String = "",
        dateOfBirth: Date = Date.now,
        backgroundColor: ColorType = .blue,
        onSave: @escaping (String, String, Date, ColorType) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._name = State(initialValue: name)
        self._breed = State(initialValue: breed)
        self._dateOfBirth = State(initialValue: dateOfBirth)
        self._backgroundColor = State(initialValue: backgroundColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Breed", text: $breed)
                        .textInputAutocapitalization(.words)

                    DatePicker(
                        "Birthday",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )
                }

                Section("Card Color") {
                    Picker("Color", selection: $backgroundColor) {
                        ForEach(ColorType.allCases, id: \.self) { color in
                            DogColorPickerRow(color: color)
                                .tag(color)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveDog)
                        .disabled(trimmedBreed.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveDog() {
        onSave(trimmedName, trimmedBreed, dateOfBirth, backgroundColor)
        dismiss()
    }
}

#Preview {
    DogFormView { _, _, _, _ in }
}
