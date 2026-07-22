//
//  DogFormColorButton.swift
//  Pawsona
//

import SwiftUI

struct DogFormColorButton: View {
    let color: ColorType
    @Binding var selectedColor: ColorType

    private var isSelected: Bool {
        selectedColor == color
    }

    var body: some View {
        Button {
            selectedColor = color
        } label: {
            DogColorPickerRow(
                color: color,
                isSelected: isSelected
            )
            .frame(width: 17, height: 17)
            // The swatch stays 17pt to match the hifi; the button around it is
            // what has to clear 44x44pt.
            .frame(maxWidth: 28, minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.accessibilityName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    DogFormColorButton(color: .blue, selectedColor: .constant(.blue))
}
