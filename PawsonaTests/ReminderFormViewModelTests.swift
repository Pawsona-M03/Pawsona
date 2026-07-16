//
//  ReminderFormViewModelTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 17/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("ReminderFormViewModel")
struct ReminderFormViewModelTests {
    private func makeService() -> (NotificationService, SpyNotificationCenter) {
        let spy = SpyNotificationCenter()
        return (NotificationService(center: spy), spy)
    }

    private func futureDate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now.addingTimeInterval(7200)
    }

    @Test("Save disabled when title is empty")
    func saveDisabledForEmptyTitle() {
        let (service, _) = makeService()
        let viewModel = ReminderFormViewModel(notificationService: service)
        viewModel.title = "   "
        viewModel.dueDate = futureDate()

        #expect(viewModel.isSaveEnabled == false)
    }

    @Test("Save disabled when date is in the past")
    func saveDisabledForPastDate() throws {
        let (service, _) = makeService()
        let viewModel = ReminderFormViewModel(notificationService: service)
        viewModel.title = "Vet visit"
        viewModel.dueDate = try #require(Calendar.current.date(byAdding: .hour, value: -1, to: .now))

        #expect(viewModel.isSaveEnabled == false)
    }

    @Test("Save enabled with a title and future date")
    func saveEnabledWhenValid() {
        let (service, _) = makeService()
        let viewModel = ReminderFormViewModel(notificationService: service)
        viewModel.title = "Vet visit"
        viewModel.dueDate = futureDate()

        #expect(viewModel.isSaveEnabled)
    }

    @Test("Saving a new reminder inserts it and schedules exactly one notification")
    func saveInsertsAndSchedules() async throws {
        let context = try TestSupport.makeContext()
        let (service, spy) = makeService()
        let viewModel = ReminderFormViewModel(notificationService: service)
        viewModel.title = "Vet visit"
        viewModel.dueDate = futureDate()
        viewModel.category = .vaccine

        await viewModel.save(in: context)

        let reminders = try context.fetch(FetchDescriptor<Reminder>())
        #expect(reminders.count == 1)
        #expect(reminders.first?.title == "Vet visit")
        #expect(spy.added.count == 1)
    }

    @Test("Selected puppies are linked to the saved reminder")
    func saveLinksSelectedPuppies() async throws {
        let context = try TestSupport.makeContext()
        let (service, _) = makeService()
        let rex = Dog(name: "Rex", breed: "Husky")
        let luna = Dog(name: "Luna", breed: "Corgi")
        context.insert(rex)
        context.insert(luna)

        let viewModel = ReminderFormViewModel(notificationService: service)
        viewModel.title = "Group walk"
        viewModel.dueDate = futureDate()
        viewModel.toggleDog(rex)
        viewModel.toggleDog(luna)

        await viewModel.save(in: context)

        let reminder = try #require(try context.fetch(FetchDescriptor<Reminder>()).first)
        let names = Set((reminder.dogList ?? []).compactMap(\.name))
        #expect(names == ["Rex", "Luna"])
    }

    @Test("Editing pre-fills the form from the existing reminder")
    func editPreFillsForm() async throws {
        let context = try TestSupport.makeContext()
        let (service, _) = makeService()
        let reminder = Reminder(title: "Original", notes: "bring records",
                                dueDate: futureDate(), category: .medicine)
        context.insert(reminder)

        let viewModel = ReminderFormViewModel(editing: reminder, notificationService: service)

        #expect(viewModel.title == "Original")
        #expect(viewModel.notes == "bring records")
        #expect(viewModel.category == .medicine)
    }

    @Test("Editing save cancels the old notification then schedules the new one")
    func editSaveCancelsThenSchedules() async throws {
        let context = try TestSupport.makeContext()
        let (service, spy) = makeService()
        let reminder = Reminder(title: "Original", dueDate: futureDate(), category: .medicine)
        context.insert(reminder)

        let viewModel = ReminderFormViewModel(editing: reminder, notificationService: service)
        viewModel.title = "Edited"

        await viewModel.save(in: context)

        #expect(spy.removedIdentifiers == [reminder.id.uuidString])
        #expect(spy.added.count == 1)
        #expect(spy.added.first?.content.title == "Edited")
        // No duplicate row — still editing the same reminder.
        #expect(try context.fetch(FetchDescriptor<Reminder>()).count == 1)
    }
}
