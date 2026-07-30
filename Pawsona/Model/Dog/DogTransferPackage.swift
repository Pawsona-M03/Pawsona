//
//  DogTransferPackage.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import Foundation

/// A `Codable` snapshot of a `Dog` and its vaccine records, used to move a puppy's data
/// between devices (e.g. via AirDrop) without exposing SwiftData's `@Model` machinery.
struct DogTransferPackage: Codable {
    var name: String?
    var breed: String
    var backgroundColor: ColorType
    var dateOfBirth: Date?
    var weight: Double?
    var sex: Sex?
    var photoData: Data?
    var vaccineRecords: [VaccineRecordTransferPackage]

    @MainActor
    init(dog: Dog) {
        name = dog.name
        breed = dog.breed
        backgroundColor = dog.backgroundColor
        dateOfBirth = dog.dateOfBirth
        weight = dog.weight
        sex = dog.sex
        photoData = dog.photoData
        vaccineRecords = (dog.vaccineRecords ?? []).map(VaccineRecordTransferPackage.init)
    }

    @MainActor
    func makeDog() -> Dog {
        let dog = Dog(
            name: name,
            breed: breed,
            backgroundColor: backgroundColor,
            dateOfBirth: dateOfBirth,
            weight: weight,
            sex: sex,
            photoData: photoData
        )

        dog.vaccineRecords = vaccineRecords.map { $0.makeVaccineRecord(dog: dog) }

        return dog
    }
}
