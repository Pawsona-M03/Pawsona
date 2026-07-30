//
//  ReminderTypePicker.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 21/07/26.
//

import SwiftUI

/// Type selector for the reminder form. Uses a popover rather than a `Menu`
/// because UIKit-backed menus tint every row's icon with the app accent, and
/// the hifi needs each type's own color on its dot.
struct ReminderTypePicker: View {
    @Binding var selection: ReminderType
    @State private var isShowingOptions = false

    var body: some View {
        Button {
            isShowingOptions = true
        } label: {
            HStack {
                Circle()
                    .fill(selection.color)
                    .frame(width: 10, height: 10)
                Text(selection.displayName)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Type")
        .accessibilityValue(selection.displayName)
        .popover(isPresented: $isShowingOptions) {
            options
                .presentationCompactAdaptation(.popover)
        }
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ReminderType.allCases, id: \.self) { type in
                Button {
                    selection = type
                    isShowingOptions = false
                } label: {
                    HStack {
                        Circle()
                            .fill(type.color)
                            .frame(width: 10, height: 10)
                        Text(type.displayName)
                        Spacer()
                        Image(systemName: "checkmark")
                            .opacity(selection == type ? 1 : 0)
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == type ? .isSelected : [])

                if type != ReminderType.allCases.last {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .frame(idealWidth: 220)
    }
}

#Preview {
    @Previewable @State var selection = ReminderType.vitamin

    Form {
        LabeledContent("Type") {
            ReminderTypePicker(selection: $selection)
        }
    }
}
