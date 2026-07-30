//
//  NotificationService.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 15/07/26.
//

import Foundation
import UserNotifications

/// Schedules and cancels local notifications for reminders. Backed by
/// `UNUserNotificationCenter` in the app and by a spy in tests.
@Observable
final class NotificationService {
    enum PermissionState: Equatable {
        case notDetermined, granted, denied
    }

    private(set) var permissionState: PermissionState = .notDetermined
    private let center: NotificationScheduling

    init(center: NotificationScheduling = UNUserNotificationCenter.current()) {
        self.center = center
    }

    /// Requests notification permission and records the outcome as visible
    /// state. A thrown error or a denial both land in `.denied` — never a crash.
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionState = granted ? .granted : .denied
        } catch {
            permissionState = .denied
        }
    }

    /// Registers (or, for matching ids, replaces) the pending notifications for
    /// the reminder. A one-shot reminder gets a single calendar trigger (skipped
    /// when already past — it could never fire); a repeating one gets a weekly
    /// trigger per selected weekday at the reminder's time.
    func schedule(_ reminder: Reminder) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes { content.body = notes }
        content.sound = .default

        if reminder.repeatDays.isEmpty {
            guard reminder.dueDate > .now else { return }
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminder.dueDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString, content: content, trigger: trigger
            )
            try? await center.add(request)
        } else {
            let time = Calendar.current.dateComponents([.hour, .minute], from: reminder.dueDate)
            for weekday in reminder.repeatDays {
                var components = time
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(reminder.id.uuidString)-\(weekday)", content: content, trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    /// Cancels the reminder's pending notifications, if any. Removes the
    /// one-shot id and every possible weekday id so an edit that changes the
    /// repeat days can never leave stale triggers behind.
    func cancel(_ reminder: Reminder) {
        center.removePendingNotificationRequests(withIdentifiers: Self.identifiers(for: reminder))
    }

    static func identifiers(for reminder: Reminder) -> [String] {
        let base = reminder.id.uuidString
        return [base] + (1...7).map { "\(base)-\($0)" }
    }
}
