//
//  PuppySelectionRow.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import SwiftUI

/// A single selectable puppy in the reminder form's multi-select list.
struct PuppySelectionRow: View {
    let dog: Dog
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        SelectionRow(title: dog.name ?? "Puppy", isSelected: isSelected, toggle: toggle) {
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }
}
