//
//  DogFormColorPickerView.swift
//  Pawsona
//

import SwiftUI

struct DogFormColorPickerView: View {
    @Binding var backgroundColor: ColorType

    var body: some View {
        // No explicit spacing: each button spreads to an equal share of the
        // width instead, which is what buys the 44pt hit target without eight
        // fixed 44pt boxes overflowing the screen.
        HStack(spacing: 0) {
            ForEach(ColorType.allCases, id: \.self) { color in
                DogFormColorButton(
                    color: color,
                    selectedColor: $backgroundColor
                )
            }
        }
    }
}

#Preview {
    DogFormColorPickerView(backgroundColor: .constant(.blue))
}
