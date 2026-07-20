//
//  RepeatDayPicker.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 20/07/26.
//

import SwiftUI

/// Seven S M T W T F S toggle circles, Clock-alarm style. Values are
/// `Calendar` weekday numbers (1 = Sunday … 7 = Saturday).
struct RepeatDayPicker: View {
    @Binding var selectedDays: Set<Int>

    private let calendar = Calendar.current

    var body: some View {
        HStack {
            ForEach(1...7, id: \.self) { weekday in
                let isSelected = selectedDays.contains(weekday)

                Button {
                    if isSelected {
                        selectedDays.remove(weekday)
                    } else {
                        selectedDays.insert(weekday)
                    }
                } label: {
                    Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                        .font(.body)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(
                            isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                            in: .circle
                        )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(calendar.weekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
