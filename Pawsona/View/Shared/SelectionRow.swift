//
//  SelectionRow.swift
//  Pawsona
//

import SwiftUI

struct SelectionRow<TrailingContent: View>: View {
    let title: String
    let isSelected: Bool
    let toggle: () -> Void
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                trailingContent()
            }
            .contentShape(.rect)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
