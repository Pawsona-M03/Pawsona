//
//  DogTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 14/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("Dog model")
struct DogTests {
    @Test("Creating a dog with only color and breed inserts successfully")
    func minimalDogInserts() throws {
        let context = try TestSupport.makeContext()
        context.insert(Dog(breed: "Golden Retriever", backgroundColor: .yellow))
        try context.save()

        let dogs = try context.fetch(FetchDescriptor<Dog>())
        #expect(dogs.count == 1)
        #expect(dogs.first?.breed == "Golden Retriever")
        #expect(dogs.first?.backgroundColor == .yellow)
    }

    @Test("Age is computed from a known date of birth")
    func ageComputedFromDateOfBirth() throws {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: .now)
        let dog = Dog(breed: "Poodle", dateOfBirth: twoYearsAgo)
        #expect(dog.age == 2)
    }

    @Test("Age is nil when date of birth is unknown")
    func ageNilWithoutDateOfBirth() {
        #expect(Dog(breed: "Poodle").age == nil)
    }

    @Test("Age text shows only years once at least one year old")
    func ageTextShowsOnlyYears() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 27)))
        let dateOfBirth = try #require(calendar.date(from: DateComponents(year: 2024, month: 5, day: 12)))

        #expect(Dog.ageText(from: dateOfBirth, to: now, calendar: calendar) == "2 years old")
    }

    @Test("Age text shows months before one year old")
    func ageTextShowsMonthsBeforeOneYear() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 27)))
        let dateOfBirth = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 12)))

        #expect(Dog.ageText(from: dateOfBirth, to: now, calendar: calendar) == "2 months old")
    }

    @Test("Age text shows days before one month old")
    func ageTextShowsDaysBeforeOneMonth() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 27)))
        let dateOfBirth = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 20)))

        #expect(Dog.ageText(from: dateOfBirth, to: now, calendar: calendar) == "7 days old")
    }

    @Test("Nil name, weight, sex, and photo round-trip through the container")
    func nilOptionalsRoundTrip() throws {
        let context = try TestSupport.makeContext()
        context.insert(Dog(breed: "Beagle"))
        try context.save()

        let dog = try #require(try context.fetch(FetchDescriptor<Dog>()).first)
        #expect(dog.name == nil)
        #expect(dog.weight == nil)
        #expect(dog.sex == nil)
        #expect(dog.photoData == nil)
    }
}
