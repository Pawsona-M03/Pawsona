//
//  WeekStripView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 20/07/26.
//

import SwiftUI

/// One selectable week of day circles (like the hifi's Sun–Sat strip). Today's
/// column is labeled "Today"; the selected day's circle is filled with the tint.
struct WeekStripView: View {
    let days: [Date]
    @Binding var selectedDate: Date

    private let calendar = Calendar.current

    var body: some View {
        HStack {
            ForEach(days, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(day)

                Button {
                    selectedDate = calendar.startOfDay(for: day)
                } label: {
                    VStack(spacing: 8) {
                        Text(isToday ? "Today" : day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.subheadline)
                            .bold(isToday)
                            .foregroundStyle(isToday ? .primary : .secondary)

                        Text(day.formatted(.dateTime.day()))
                            .font(.body)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(
                                isSelected ? Color.accentColor : Color.clear,
                                    in: Circle()
                            )
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
