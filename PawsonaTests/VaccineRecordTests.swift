//
//  VaccineRecordTests.swift
//  PawsonaTests
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("VaccineRecord model")
struct VaccineRecordTests {
    @Test("Record round-trips with vaccine and date")
    func vaccineAndDateRoundTrip() throws {
        let context = try TestSupport.makeContext()
        let given = Date(timeIntervalSince1970: 1_752_451_200)
        context.insert(VaccineRecord(vaccine: .rabies, dateGiven: given))
        try context.save()

        let record = try #require(try context.fetch(FetchDescriptor<VaccineRecord>()).first)
        #expect(record.vaccine == .rabies)
        #expect(record.dateGiven == given)
    }

    @Test("Record linked to a dog appears in the dog's vaccine records")
    func linkedRecordAppearsOnDog() throws {
        let context = try TestSupport.makeContext()
        let dog = Dog(name: "Rex", breed: "Husky")
        context.insert(dog)
        context.insert(VaccineRecord(vaccine: .parvovirus, dog: dog))
        try context.save()

        #expect(dog.vaccineRecords?.count == 1)
        #expect(dog.vaccineRecords?.first?.vaccine == .parvovirus)
    }

    @Test("Record with no dog is valid (scan-before-assign case)")
    func nilDogIsValid() throws {
        let context = try TestSupport.makeContext()
        context.insert(VaccineRecord(vaccine: .bordetella))
        try context.save()

        let record = try #require(try context.fetch(FetchDescriptor<VaccineRecord>()).first)
        #expect(record.dog == nil)
    }
}
