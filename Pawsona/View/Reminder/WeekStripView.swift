//
//  WeekStripView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 20/07/26.
//

import SwiftUI

/// A horizontally scrolling strip of day circles (the hifi's calendar header).
/// Behaves like a wheel picker laid on its side: seven columns fill the width,
/// scrolling snaps a column at a time, and whichever day lands in the middle
/// becomes the selection. Weekdays are single letters, except today, which
/// reads "Today".
struct WeekStripView: View {
    let days: [Date]
    @Binding var selectedDate: Date

    @State private var scrollPosition = ScrollPosition()
    @ScaledMetric(relativeTo: .body) private var daySize = 38
    @ScaledMetric(relativeTo: .title2) private var selectedDaySize = 52

    /// Seven visible columns, so the middle one is always the fourth. Because
    /// every column is exactly 1/7 of the width, the scroll view's
    /// edge-aligned snapping lands a day dead centre for free.
    private let visibleDays = 7
    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    dayColumn(for: day)
                        .containerRelativeFrame(
                            .horizontal,
                            count: visibleDays,
                            spacing: 0
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($scrollPosition, anchor: .center)
        .frame(height: selectedDaySize + labelHeight)
        .onAppear {
            center(on: selectedDate, animated: false)
        }
        .onChange(of: selectedDate) { _, newValue in
            // Taps (and outside changes) pull the strip to match.
            guard scrollPosition.viewID(type: Date.self) != newValue else { return }
            center(on: newValue, animated: true)
        }
        .onChange(of: scrollPosition) { _, newValue in
            // Scrolling pushes the centred day back into the selection.
            guard let centred = newValue.viewID(type: Date.self), centred != selectedDate else { return }
            selectedDate = centred
        }
    }

    /// Room for the weekday caption above the circles.
    private var labelHeight: CGFloat { daySize }

    @ViewBuilder
    private func dayColumn(for day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)

        Button {
            selectedDate = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: 6) {
                Text(isToday ? "Today" : day.formatted(.dateTime.weekday(.narrow)))
                    .font(.subheadline)
                    .bold(isSelected || isToday)
                    .foregroundStyle(isSelected || isToday ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(day.formatted(.dateTime.day()))
                    .font(isSelected ? .title2 : .body)
                    .bold(isSelected)
                    .foregroundStyle(isSelected ? Color(.primaryBrown) : Color.primary)
                    .frame(
                        width: isSelected ? selectedDaySize : daySize,
                        height: isSelected ? selectedDaySize : daySize
                    )
                    .background(
                        isSelected ? Color(.secondaryBrown) : Color(.cardSurface),
                        in: .circle
                    )
                    // Fixed box so the larger selected circle doesn't shift the
                    // strip's height or its neighbours.
                    .frame(height: selectedDaySize)
            }
            .frame(maxWidth: .infinity)
            .animation(.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func center(on day: Date, animated: Bool) {
        withAnimation(animated ? .snappy : nil) {
            scrollPosition.scrollTo(id: calendar.startOfDay(for: day), anchor: .center)
        }
    }
}
