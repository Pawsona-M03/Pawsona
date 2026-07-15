//
//  Reminder.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String?
    @Relationship(inverse: \Dog.reminders) var dogList: [Dog]? = nil
    var dueDate: Date = Date.now
    var repeatRule: RepeatRule?
    var category: ReminderType = ReminderType.others

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String? = nil,
        dogList: [Dog]? = nil,
        dueDate: Date = .now,
        repeatRule: RepeatRule? = nil,
        category: ReminderType = .others
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dogList = dogList
        self.dueDate = dueDate
        self.repeatRule = repeatRule
        self.category = category
    }
}
