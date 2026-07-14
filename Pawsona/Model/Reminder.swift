//
//  Reminder.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class Reminder{
    var id: UUID
    var title: String
    var notes: String
    var dogList: [Dog]
    var reminderDateAndHour: Date
    var repeatRule: RepeatRule?
    var category: CategoryType
    
    init(
        id: UUID = .init(),
        title: String,
        notes: String,
        dogList: [Dog],
        type: CategoryType
    ){
        self.id = id
        self.title = title
        self.notes = notes
        self.dogList = dogList
        self.reminderDateAndHour = Date()
        self.repeatRule = nil
        self.category = .medicine
    }
}

enum CategoryType: String, Codable {
    case medicine
    case vitamin
    case vaccine
    case others
}

struct RepeatRule: Codable {
    var interval: Int
    var unit: RepeatUnit
}

enum RepeatUnit: String, Codable {
    case day
    case week
    case month
    case year
}
