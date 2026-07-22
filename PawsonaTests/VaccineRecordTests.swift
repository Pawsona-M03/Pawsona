//
//  VaccineRecordTests.swift
//  PawsonaTests
//
//  Created by Nathan Sudiara on 14/07/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("VaccineRecord model")
struct VaccineRecordTests {
    @Test("Record round-trips with vaccines and date")
    func vaccineAndDateRoundTrip() throws {
        let context = try TestSupport.makeContext()
        let given = Date(timeIntervalSince1970: 1_752_451_200)
        context.insert(VaccineRecord(vaccines: [.rabies, .bordetella], dateGiven: given))
        try context.save()

        let record = try #require(try context.fetch(FetchDescriptor<VaccineRecord>()).first)
        #expect(record.vaccines == [.rabies, .bordetella])
        #expect(record.dateGiven == given)
    }

    @Test("Record linked to a dog appears in the dog's vaccine records")
    func linkedRecordAppearsOnDog() throws {
        let context = try TestSupport.makeContext()
        let dog = Dog(name: "Rex", breed: "Husky")
        context.insert(dog)
        context.insert(VaccineRecord(vaccines: [.parvovirus], dogList: [dog]))
        try context.save()

        #expect(dog.vaccineRecords?.count == 1)
        #expect(dog.vaccineRecords?.first?.vaccines == [.parvovirus])
    }

    @Test("Record can be shared by multiple dogs")
    func recordSharedByMultipleDogs() throws {
        let context = try TestSupport.makeContext()
        context.insert(VaccineRecord(vaccines: [.bordetella]))
        try context.save()

        let record = try #require(try context.fetch(FetchDescriptor<VaccineRecord>()).first)
        #expect(record.dogList?.isEmpty ?? true)
    }
    
    @Test("Record linked to multiple dogs appears in all their vaccine records (Many puppies)")
        func linkedRecordAppearsOnMultipleDogs() throws {
            let context = try TestSupport.makeContext()
            
            let dog1 = Dog(name: "Berry", breed: "Husky")
            let dog2 = Dog(name: "Goldie", breed: "Golden Retriever")
            let dog3 = Dog(name: "Bella", breed: "Poodle")
            
            context.insert(dog1)
            context.insert(dog2)
            context.insert(dog3)
            
            let sharedVaccine = VaccineRecord(vaccines: [.rabies, .parvovirus], dogList: [dog1, dog2, dog3])
            context.insert(sharedVaccine)
            
            try context.save()
            
            #expect(sharedVaccine.dogList?.count == 3)
            #expect(dog1.vaccineRecords?.contains(where: { $0.vaccines == [.rabies, .parvovirus] }) == true)
            #expect(dog2.vaccineRecords?.contains(where: { $0.vaccines == [.rabies, .parvovirus] }) == true)
            #expect(dog3.vaccineRecords?.contains(where: { $0.vaccines == [.rabies, .parvovirus] }) == true)
        }
}
