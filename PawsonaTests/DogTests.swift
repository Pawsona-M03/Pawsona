//
//  DogTests.swift
//  PawsonaTests
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
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
