//
//  NotificationScheduling.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 15/07/26.
//

import UserNotifications

/// The slice of `UNUserNotificationCenter` that `NotificationService` needs,
/// wrapped so scheduling logic can be unit-tested without system permissions.
protocol NotificationScheduling {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

// The real center already has these exact signatures, so conformance is free.
extension UNUserNotificationCenter: NotificationScheduling {}
