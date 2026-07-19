//
//  UpcomingRemindersViewModel.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import Foundation
import Observation
import SwiftData

/// Groups upcoming reminders for the home list and handles deletion (which also
/// cancels the pending notification).
@Observable
final class UpcomingRemindersViewModel {
    /// One rendered section: a group and its reminders, soonest first.
    struct Section: Identifiable {
        let group: ReminderGroup
        let reminders: [Reminder]
        var id: ReminderGroup { group }
    }

    private let notificationService: NotificationService

    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
    }

    /// Sorts reminders soonest-first and buckets them into non-empty sections in
    /// display order (overdue → today → this week → later).
    func sections(for reminders: [Reminder], now: Date = .now) -> [Section] {
        let sorted = reminders.sorted { $0.dueDate < $1.dueDate }
        var buckets: [ReminderGroup: [Reminder]] = [:]
        for reminder in sorted {
            buckets[group(for: reminder.dueDate, now: now), default: []].append(reminder)
        }
        return ReminderGroup.allCases.compactMap { group in
            guard let reminders = buckets[group], !reminders.isEmpty else { return nil }
            return Section(group: group, reminders: reminders)
        }
    }

    func group(for dueDate: Date, now: Date, calendar: Calendar = .current) -> ReminderGroup {
        if dueDate < now { return .overdue }

        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end

        if let startOfTomorrow, dueDate < startOfTomorrow { return .today }
        if let endOfWeek, dueDate < endOfWeek { return .thisWeek }
        return .later
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
