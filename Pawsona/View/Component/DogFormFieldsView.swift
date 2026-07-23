//
//  DogFormFieldsView.swift
//  Pawsona
//

import SwiftUI

struct DogFormFieldsView: View {
    @Binding var name: String
    @Binding var breed: String
    @Binding var dateOfBirth: Date
    @Binding var weightText: String
    @Binding var sex: Sex?

    var body: some View {
        Form {
            // Breed is the one required field, so it stands alone in its own
            // section — the visual separation tells the user it's the must-fill.
            Section {
                DogBreedField(breed: $breed)
            }

            // Everything below is optional and grouped together.
            Section {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("Dog name")

                DogSexMenu(sex: $sex)

                DatePicker(
                    "Date of Birth",
                    selection: $dateOfBirth,
                    in: ...Date.now,
                    displayedComponents: .date
                )

                HStack {
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Dog weight in kilograms")
                    if !weightText.isEmpty {
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    DogFormFieldsView(
        name: .constant("Berry"),
        breed: .constant("Labrador Retriever"),
        dateOfBirth: .constant(.now),
        weightText: .constant("12.4"),
        sex: .constant(.female)
    )
}
