//
//  DogColorPickerRow.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

struct DogColorPickerRow: View {
    let color: ColorType
    var isSelected = false

    var body: some View {
        Circle()
            .fill(swatchColor)
            .frame(width: isSelected ? 28 : 16, height: isSelected ? 28 : 16)
            .overlay {
                if isSelected {
                    // Size alone shouldn't carry the selection: a ring gives it
                    // a cue that survives when the swatch colour is hard to
                    // tell apart from its neighbours.
                    Circle()
                        .strokeBorder(.primary, lineWidth: 0)
                }
            }
            .animation(.snappy, value: isSelected)
    }

    private var swatchColor: Color { color.color }
}

#Preview {
    DogColorPickerRow(color: .blue)
}
