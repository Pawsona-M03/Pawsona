//
//  UpcomingRemindersViewModel.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import Foundation
import Observation
import SwiftData

/// Backs the reminder home screen: tracks the selected day of the week strip,
/// filters reminders down to that day, and handles deletion (which also
/// cancels the pending notifications).
@Observable
final class UpcomingRemindersViewModel {
    var selectedDate: Date

    /// A year either side of today, for the horizontal day strip. Built once so
    /// scrolling doesn't rebuild ~700 dates on every redraw.
    let stripDays: [Date]

    private let notificationService: NotificationService
    private let calendar: Calendar

    init(
        notificationService: NotificationService,
        calendar: Calendar = .current,
        today: Date = .now
    ) {
        self.notificationService = notificationService
        self.calendar = calendar

        let startOfToday = calendar.startOfDay(for: today)
        self.selectedDate = startOfToday
        self.stripDays = (-365...365).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfToday)
        }
    }

    /// Reminders occurring on the given day, sorted by time of day: one-shots
    /// due that day, plus repeating reminders whose weekday matches once their
    /// start date has arrived.
    func reminders(from reminders: [Reminder], on day: Date) -> [Reminder] {
        let weekday = calendar.component(.weekday, from: day)
        return reminders.filter { reminder in
            if reminder.isRepeating {
                return reminder.repeatDays.contains(weekday)
                    && calendar.startOfDay(for: reminder.dueDate) <= day
            }
            return calendar.isDate(reminder.dueDate, inSameDayAs: day)
        }
        .sorted { minutesIntoDay($0.dueDate) < minutesIntoDay($1.dueDate) }
    }

    private func minutesIntoDay(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func delete(_ reminder: Reminder, in modelContext: ModelContext) {
        notificationService.cancel(reminder)
        modelContext.delete(reminder)
        do {
            try modelContext.save()
        } catch {
            // Deletion failed to persist; the @Query will still reflect reality.
        }
    }
}
