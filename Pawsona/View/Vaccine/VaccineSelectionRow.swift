//
//  VaccineSelectionRow.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftUI

/// A single selectable vaccine row (multi-select, checkbox style).
struct VaccineSelectionRow: View {
    let vaccine: VaccineType
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        SelectionRow(title: vaccine.displayName, isSelected: isSelected, toggle: toggle) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? Color(.vaccineBrown) : .secondary)
        }
    }
}

#Preview {
    VaccineSelectionRow(vaccine: .parvovirus, isSelected: true) {}
    VaccineSelectionRow(vaccine: .rabies, isSelected: false) {}
}
