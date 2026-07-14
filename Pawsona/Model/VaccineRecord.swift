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
    var name: String = ""
    var dateGiven: Date = Date.now
    var notes: String?
    @Relationship(inverse: \Dog.vaccineRecords) var dog: Dog?

    init(
        id: UUID = UUID(),
        name: String = "",
        dateGiven: Date = .now,
        notes: String? = nil,
        dog: Dog? = nil
    ) {
        self.id = id
        self.name = name
        self.dateGiven = dateGiven
        self.notes = notes
        self.dog = dog
    }
}
