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
        Button(action: toggle) {
            HStack {
                Text(dog.name ?? "Puppy")
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
