//
//  NotificationServiceTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 15/07/26.
//

import Foundation
import Testing
import UserNotifications
@testable import Pawsona

/// In-memory stand-in for `UNUserNotificationCenter` that records what the
/// service scheduled and cancelled, so scheduling logic is testable without
/// system permissions.
final class SpyNotificationCenter: NotificationScheduling {
    var authorizationResult = true
    var authorizationError: Error?
    private(set) var added: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        if let authorizationError { throw authorizationError }
        return authorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        // Mirror the real center: a request with the same id replaces the old one.
        added.removeAll { $0.identifier == request.identifier }
        added.append(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        added
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        added.removeAll { identifiers.contains($0.identifier) }
        removedIdentifiers.append(contentsOf: identifiers)
    }
}

@Suite("NotificationService")
struct NotificationServiceTests {
    @Test("Scheduling a future reminder registers exactly one matching request")
    func scheduleFutureReminder() async throws {
        let spy = SpyNotificationCenter()
        let service = NotificationService(center: spy)
        let due = try #require(Calendar.current.date(byAdding: .hour, value: 2, to: .now))
        let reminder = Reminder(title: "Vet visit", dueDate: due)

        try await service.schedule(reminder)

        let pending = await spy.pendingNotificationRequests()
        #expect(pending.count == 1)
        let request = try #require(pending.first)
        #expect(request.identifier == reminder.id.uuidString)
        #expect(request.content.title == "Vet visit")

        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        let expected = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: due
        )
        #expect(trigger.dateComponents == expected)
        #expect(trigger.repeats == false)
    }

    @Test("Scheduling a past reminder registers nothing")
    func schedulePastReminder() async throws {
        let spy = SpyNotificationCenter()
        let service = NotificationService(center: spy)
        let due = try #require(Calendar.current.date(byAdding: .hour, value: -2, to: .now))

        try await service.schedule(Reminder(title: "Missed dose", dueDate: due))

        let pending = await spy.pendingNotificationRequests()
        #expect(pending.isEmpty)
    }

    @Test("Rescheduling the same reminder replaces its pending request")
    func rescheduleReplaces() async throws {
        let spy = SpyNotificationCenter()
        let service = NotificationService(center: spy)
        let due = try #require(Calendar.current.date(byAdding: .hour, value: 2, to: .now))
        let reminder = Reminder(title: "Original", dueDate: due)

        try await service.schedule(reminder)
        reminder.title = "Edited"
        try await service.schedule(reminder)

        let pending = await spy.pendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.content.title == "Edited")
    }

    @Test("Cancelling removes the pending request with that id")
    func cancelRemovesRequest() async throws {
        let spy = SpyNotificationCenter()
        let service = NotificationService(center: spy)
        let due = try #require(Calendar.current.date(byAdding: .hour, value: 2, to: .now))
        let reminder = Reminder(title: "Grooming", dueDate: due)
        try await service.schedule(reminder)

        service.cancel(reminder)

        let pending = await spy.pendingNotificationRequests()
        #expect(pending.isEmpty)
        #expect(spy.removedIdentifiers == [reminder.id.uuidString])
    }

    @Test("Granted authorization sets a visible granted state")
    func permissionGranted() async {
        let spy = SpyNotificationCenter()
        spy.authorizationResult = true
        let service = NotificationService(center: spy)

        await service.requestPermission()

        #expect(service.permissionState == .granted)
    }

    @Test("Denied authorization sets a visible denied state, no crash")
    func permissionDenied() async {
        let spy = SpyNotificationCenter()
        spy.authorizationResult = false
        let service = NotificationService(center: spy)

        await service.requestPermission()

        #expect(service.permissionState == .denied)
    }

    @Test("A thrown authorization error lands in denied, not a crash")
    func permissionErrorFallsBackToDenied() async {
        let spy = SpyNotificationCenter()
        spy.authorizationError = CocoaError(.userCancelled)
        let service = NotificationService(center: spy)

        await service.requestPermission()

        #expect(service.permissionState == .denied)
    }
}
