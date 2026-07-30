//
//  DogSexPicker.swift
//  Pawsona
//

import SwiftUI

/// A standard form row for picking the dog's gender: title on the leading edge,
/// current value plus the menu chevron on the trailing edge — the same shape
/// system apps use for rows such as Calendar's "Travel Time".
struct DogSexPicker: View {
    @Binding var sex: Sex?

    var body: some View {
        Picker("Gender", selection: $sex) {
            Text("None")
                .tag(Sex?.none)

            ForEach(Sex.allCases, id: \.self) { sex in
                Text(sex.displayName)
                    .tag(Sex?.some(sex))
            }
        }
        .pickerStyle(.menu)
        // System apps show the current value in secondary grey, not the accent
        // colour — the menu chevron is what signals the row is interactive.
        .tint(.secondary)
    }
}

private extension Sex {
    var displayName: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        }
    }
}

#Preview {
    @Previewable @State var sex: Sex? = .female

    Form {
        DogSexPicker(sex: $sex)
    }
}
