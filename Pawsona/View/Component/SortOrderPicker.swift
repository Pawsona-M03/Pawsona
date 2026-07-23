//
//  SortOrderPicker.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

/// The contents of the "Sort" menu: one section to pick the field, and a second
/// section to pick the direction. Each renders as a checkmarked list, so the
/// active field and direction are both visible at a glance.
struct SortOrderPicker: View {
    @Binding var selection: DogSortOption
    @Binding var direction: DogSortDirection

    var body: some View {
        Picker("Sort By", selection: $selection) {
            ForEach(DogSortOption.allCases) { option in
                Text(option.title).tag(option)
            }
        }

        Picker("Order", selection: $direction) {
            ForEach(DogSortDirection.allCases) { option in
                Text(selection.directionTitle(for: option)).tag(option)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = DogSortOption.dateAdded
    @Previewable @State var direction = DogSortDirection.descending

    Menu("Sort", systemImage: "arrow.up.arrow.down") {
        SortOrderPicker(selection: $selection, direction: $direction)
    }
}
