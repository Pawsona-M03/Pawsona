//
//  ReminderTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 14/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("Reminder model")
struct ReminderTests {
    @Test("Reminder round-trips with each category", arguments: ReminderType.allCases)
    func categoryRoundTrips(category: ReminderType) throws {
        let context = try TestSupport.makeContext()
        context.insert(Reminder(title: "Checkup", category: category))
        try context.save()

        let reminder = try #require(try context.fetch(FetchDescriptor<Reminder>()).first)
        #expect(reminder.category == category)
        #expect(reminder.title == "Checkup")
    }

    @Test("Repeat days round-trip and drive the repeat summary")
    func repeatDaysRoundTrip() throws {
        let context = try TestSupport.makeContext()
        context.insert(Reminder(title: "Vitamin", repeatDays: [5], category: .vitamin))
        try context.save()

        let reminder = try #require(try context.fetch(FetchDescriptor<Reminder>()).first)
        #expect(reminder.repeatDays == [5])
        #expect(reminder.isRepeating)
        #expect(reminder.repeatSummary == "Every \(Calendar.current.weekdaySymbols[4])")
        #expect(Reminder.repeatSummary(for: []) == nil)
        #expect(Reminder.repeatSummary(for: Set(1...7)) == "Every Day")
    }

    @Test("Reminder with no linked dogs is valid")
    func noLinkedDogsIsValid() throws {
        let context = try TestSupport.makeContext()
        context.insert(Reminder(title: "Vitamin time", category: .vitamin))
        try context.save()

        let reminder = try #require(try context.fetch(FetchDescriptor<Reminder>()).first)
        #expect(reminder.dogList?.isEmpty ?? true)
    }

    @Test("Linking two dogs persists and reads back")
    func twoLinkedDogsPersist() throws {
        let context = try TestSupport.makeContext()
        let rex = Dog(name: "Rex", breed: "Husky")
        let luna = Dog(name: "Luna", breed: "Corgi")
        context.insert(rex)
        context.insert(luna)
        context.insert(Reminder(title: "Rabies shot", dogList: [rex, luna], category: .vaccine))
        try context.save()

        let reminder = try #require(try context.fetch(FetchDescriptor<Reminder>()).first)
        let names = Set((reminder.dogList ?? []).compactMap(\.name))
        #expect(names == ["Rex", "Luna"])
        #expect(rex.reminders?.count == 1)
    }
}
