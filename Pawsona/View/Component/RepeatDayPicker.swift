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
                        .bold(isSelected)
                        // Matches the week strip's day picker, so the two
                        // day-selection controls read as the same control.
                        .foregroundStyle(isSelected ? Color(.primaryBrown) : Color.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(
                            isSelected ? Color(.secondaryBrown) : Color(.appBackground),
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
