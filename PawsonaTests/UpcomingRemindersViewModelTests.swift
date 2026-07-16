//
//  UpcomingRemindersViewModelTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 19/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("UpcomingRemindersViewModel")
struct UpcomingRemindersViewModelTests {
    private func makeService() -> (NotificationService, SpyNotificationCenter) {
        let spy = SpyNotificationCenter()
        return (NotificationService(center: spy), spy)
    }

    /// A deterministic "now" 1.5 days into the current week so that "tomorrow"
    /// is still inside this week regardless of which weekday the tests run on.
    private func fixedNow() throws -> Date {
        let calendar = Calendar.current
        let weekStart = try #require(calendar.dateInterval(of: .weekOfYear, for: .now)?.start)
        return try #require(calendar.date(byAdding: .hour, value: 36, to: weekStart))
    }

    @Test("A reminder is grouped by how far away its due date is")
    func groupsByDueDate() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current

        let overdue = Reminder(title: "Overdue",
                               dueDate: try #require(calendar.date(byAdding: .hour, value: -1, to: now)))
        let today = Reminder(title: "Today",
                             dueDate: try #require(calendar.date(byAdding: .hour, value: 1, to: now)))
        let thisWeek = Reminder(title: "This week",
                                dueDate: try #require(calendar.date(byAdding: .day, value: 2, to: now)))
        let later = Reminder(title: "Later",
                             dueDate: try #require(calendar.date(byAdding: .day, value: 8, to: now)))

        let sections = viewModel.sections(for: [later, today, overdue, thisWeek], now: now)

        #expect(sections.map(\.group) == [.overdue, .today, .thisWeek, .later])
        #expect(sections.first(where: { $0.group == .today })?.reminders.first?.title == "Today")
    }

    @Test("A reminder late today (23:59) still groups as Today")
    func lateTodayGroupsAsToday() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current
        let endOfToday = try #require(
            calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)
        )

        #expect(viewModel.group(for: endOfToday, now: now) == .today)
    }

    @Test("Midnight tomorrow crosses out of Today")
    func midnightTomorrowIsNotToday() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current
        let startOfTomorrow = try #require(
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        )

        // fixedNow() is early in the week, so tomorrow is still this week.
        #expect(viewModel.group(for: startOfTomorrow, now: now) == .thisWeek)
    }

    @Test("A time earlier today but already past groups as Overdue, not Today")
    func earlierTodayButPastIsOverdue() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current
        let earlierToday = try #require(calendar.date(byAdding: .minute, value: -1, to: now))

        #expect(viewModel.group(for: earlierToday, now: now) == .overdue)
    }

    @Test("A reminder due exactly now counts as Today")
    func exactlyNowIsToday() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()

        #expect(viewModel.group(for: now, now: now) == .today)
    }

    @Test("Empty groups are omitted")
    func omitsEmptyGroups() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current
        let today = Reminder(title: "Today",
                             dueDate: try #require(calendar.date(byAdding: .hour, value: 1, to: now)))

        let sections = viewModel.sections(for: [today], now: now)

        #expect(sections.map(\.group) == [.today])
    }

    @Test("Within a group reminders are sorted soonest first")
    func sortsWithinGroup() throws {
        let (service, _) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let now = try fixedNow()
        let calendar = Calendar.current
        let later = Reminder(title: "Later today",
                             dueDate: try #require(calendar.date(byAdding: .hour, value: 5, to: now)))
        let sooner = Reminder(title: "Sooner today",
                              dueDate: try #require(calendar.date(byAdding: .hour, value: 1, to: now)))

        let sections = viewModel.sections(for: [later, sooner], now: now)
        let todayTitles = try #require(sections.first(where: { $0.group == .today })).reminders.map(\.title)

        #expect(todayTitles == ["Sooner today", "Later today"])
    }

    @Test("Deleting a reminder cancels its notification and removes it")
    func deleteCancelsAndRemoves() throws {
        let context = try TestSupport.makeContext()
        let (service, spy) = makeService()
        let viewModel = UpcomingRemindersViewModel(notificationService: service)
        let reminder = Reminder(title: "Grooming", dueDate: .now.addingTimeInterval(3600))
        context.insert(reminder)
        try context.save()

        viewModel.delete(reminder, in: context)

        #expect(spy.removedIdentifiers == [reminder.id.uuidString])
        #expect(try context.fetch(FetchDescriptor<Reminder>()).isEmpty)
    }
}
