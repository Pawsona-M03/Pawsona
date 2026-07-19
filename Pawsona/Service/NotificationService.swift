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

    /// Registers (or, for a matching id, replaces) one pending notification for
    /// the reminder. Reminders due in the past are skipped — they can never fire.
    func schedule(_ reminder: Reminder) async throws {
        guard reminder.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes { content.body = notes }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: reminder.dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString, content: content, trigger: trigger
        )
        try await center.add(request)
    }

    /// Cancels the pending notification for the reminder, if any.
    func cancel(_ reminder: Reminder) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
}
