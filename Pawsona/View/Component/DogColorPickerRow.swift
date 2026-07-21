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
                    Circle()
                        .stroke(.primary, lineWidth: 0)
                }
            }
            .animation(.snappy, value: isSelected)
    }

    private var title: String {
        switch color {
        case .red:
            "Red"
        case .orange:
            "Orange"
        case .yellow:
            "Yellow"
        case .green:
            "Green"
        case .blue:
            "Blue"
        case .purple:
            "Purple"
        case .pink:
            "Pink"
        case .gray:
            "Gray"
        }
    }

    private var swatchColor: Color {
        switch color {
        case .red:
            .red
        case .orange:
            .orange
        case .yellow:
            .yellow
        case .green:
            .green
        case .blue:
            .blue
        case .purple:
            .purple
        case .pink:
            .pink
        case .gray:
            .gray
        }
    }
}

#Preview {
    DogColorPickerRow(color: .blue)
}
