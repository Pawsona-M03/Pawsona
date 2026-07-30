//
//  VaccineRecord.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class VaccineRecord {
    var id: UUID = UUID()
    var vaccines: [VaccineType] = []
    var dateGiven: Date = Date.now
    var notes: String?
    @Relationship(inverse: \Dog.vaccineRecords) var dogList: [Dog]?

    var vaccineNames: String {
        guard !vaccines.isEmpty else {
            return "No vaccines selected"
        }

        return vaccines.map(\.displayName).joined(separator: ", ")
    }

    var dogNames: String {
        let names = (dogList ?? [])
            .compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else {
            return "No dogs selected"
        }

        return names.joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        vaccines: [VaccineType] = [],
        dateGiven: Date = .now,
        notes: String? = nil,
        dogList: [Dog]? = nil
    ) {
        self.id = id
        self.vaccines = vaccines
        self.dateGiven = dateGiven
        self.notes = notes
        self.dogList = dogList
    }
}
