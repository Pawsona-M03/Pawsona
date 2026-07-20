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
    @Relationship(inverse: \Dog.reminders) var dogList: [Dog]?
    var dueDate: Date = Date.now
    /// `Calendar` weekday numbers (1 = Sunday … 7 = Saturday) the reminder
    /// repeats on, Clock-alarm style. Empty means it fires once.
    var repeatDays: [Int] = []
    var category: ReminderType = ReminderType.others

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String? = nil,
        dogList: [Dog]? = nil,
        dueDate: Date = .now,
        repeatDays: [Int] = [],
        category: ReminderType = .others
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dogList = dogList
        self.dueDate = dueDate
        self.repeatDays = repeatDays
        self.category = category
    }
}

extension Reminder {
    var isRepeating: Bool { !repeatDays.isEmpty }

    /// "Every Day", "Every Thursday", or "Every Mon, Tue" — nil when not repeating.
    var repeatSummary: String? { Self.repeatSummary(for: Set(repeatDays)) }

    static func repeatSummary(for days: Set<Int>, calendar: Calendar = .current) -> String? {
        guard !days.isEmpty else { return nil }
        if days.count == 7 { return "Every Day" }
        let sorted = days.sorted()
        if let only = sorted.first, sorted.count == 1 {
            return "Every \(calendar.weekdaySymbols[only - 1])"
        }
        let names = sorted.map { calendar.shortWeekdaySymbols[$0 - 1] }
        return "Every \(names.joined(separator: ", "))"
    }
}
