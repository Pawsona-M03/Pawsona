//
//  SortOrderPicker.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct SortOrderPicker: View {
    @Binding var selection: DogSortOption

    var body: some View {
        Picker("Sort By", selection: $selection) {
            ForEach(DogSortOption.allCases) { option in
                Text(option.title).tag(option)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = DogSortOption.dateAdded
    SortOrderPicker(selection: $selection)
}
