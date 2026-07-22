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

    /// Form rows grow with Dynamic Type rather than clipping at a fixed 60pt.
    @ScaledMetric(relativeTo: .body) private var rowHeight = 60

    var body: some View {
        VStack(spacing: 0) {
            DogBreedField(breed: $breed, rowHeight: rowHeight)

            Divider()

            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Dog name")
                .frame(minHeight: rowHeight)

            Divider()

            DogSexMenu(sex: $sex, rowHeight: rowHeight)

            Divider()

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                displayedComponents: .date
            )
            .frame(minHeight: rowHeight)

            Divider()

            TextField("Weight (kg)", text: $weightText)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Dog weight")
                .frame(minHeight: rowHeight)
        }
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
