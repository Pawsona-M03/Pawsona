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
    private let calendar = Calendar.current

    private func makeViewModel() -> (UpcomingRemindersViewModel, SpyNotificationCenter) {
        let spy = SpyNotificationCenter()
        let service = NotificationService(center: spy)
        return (UpcomingRemindersViewModel(notificationService: service), spy)
    }

    private func day(_ offset: Int, from date: Date = .now) throws -> Date {
        let base = calendar.startOfDay(for: date)
        return try #require(calendar.date(byAdding: .day, value: offset, to: base))
    }

    @Test("The week strip has seven consecutive days containing the given date")
    func weekDaysAreSevenConsecutive() throws {
        let (viewModel, _) = makeViewModel()

        let days = viewModel.weekDays(containing: .now)

        #expect(days.count == 7)
        #expect(days.contains { calendar.isDateInToday($0) })
        for (earlier, later) in zip(days, days.dropFirst()) {
            #expect(calendar.dateComponents([.day], from: earlier, to: later).day == 1)
        }
        #expect(calendar.component(.weekday, from: try #require(days.first)) == calendar.firstWeekday)
    }

    @Test("A one-shot reminder appears only on its due day")
    func oneShotOnlyOnItsDay() throws {
        let (viewModel, _) = makeViewModel()
        let today = try day(0)
        let reminder = Reminder(title: "Vet", dueDate: today.addingTimeInterval(3600))

        #expect(viewModel.reminders(from: [reminder], on: today).count == 1)
        #expect(viewModel.reminders(from: [reminder], on: try day(1)).isEmpty)
    }

    @Test("A repeating reminder appears on matching weekdays only")
    func repeatingAppearsOnMatchingWeekday() throws {
        let (viewModel, _) = makeViewModel()
        let today = try day(0)
        let todayWeekday = calendar.component(.weekday, from: today)
        let reminder = Reminder(title: "Vitamin", dueDate: .now, repeatDays: [todayWeekday])

        #expect(viewModel.reminders(from: [reminder], on: today).count == 1)
        #expect(viewModel.reminders(from: [reminder], on: try day(1)).isEmpty)
        // Matches again a week later.
        #expect(viewModel.reminders(from: [reminder], on: try day(7)).count == 1)
    }

    @Test("A repeating reminder does not appear before its start date")
    func repeatingHiddenBeforeStartDate() throws {
        let (viewModel, _) = makeViewModel()
        let nextWeek = try day(7)
        let weekday = calendar.component(.weekday, from: nextWeek)
        let reminder = Reminder(title: "Vitamin", dueDate: nextWeek, repeatDays: [weekday])

        #expect(viewModel.reminders(from: [reminder], on: try day(0)).isEmpty)
        #expect(viewModel.reminders(from: [reminder], on: nextWeek).count == 1)
    }

    @Test("A day's reminders are sorted by time of day, repeats included")
    func sortsByTimeOfDay() throws {
        let (viewModel, _) = makeViewModel()
        let today = try day(0)
        let weekday = calendar.component(.weekday, from: today)
        let nineAM = try #require(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today))
        let tenAM = try #require(calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today))
        let earlyRepeat = Reminder(title: "Early repeat", dueDate: nineAM, repeatDays: [weekday])
        let lateOneShot = Reminder(title: "Late one-shot", dueDate: tenAM)

        let titles = viewModel.reminders(from: [lateOneShot, earlyRepeat], on: today).map(\.title)

        #expect(titles == ["Early repeat", "Late one-shot"])
    }

    @Test("Deleting a reminder cancels its notifications and removes it")
    func deleteCancelsAndRemoves() throws {
        let context = try TestSupport.makeContext()
        let (viewModel, spy) = makeViewModel()
        let reminder = Reminder(title: "Grooming", dueDate: .now.addingTimeInterval(3600))
        context.insert(reminder)
        try context.save()

        viewModel.delete(reminder, in: context)

        #expect(spy.removedIdentifiers.contains(reminder.id.uuidString))
        #expect(try context.fetch(FetchDescriptor<Reminder>()).isEmpty)
    }
}
