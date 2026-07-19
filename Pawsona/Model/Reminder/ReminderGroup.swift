//
//  ReminderGroup.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

/// How the upcoming-reminders list buckets reminders by how soon they are due.
/// Declared in display order.
enum ReminderGroup: CaseIterable {
    case overdue, today, thisWeek, later

    var title: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .thisWeek: "This Week"
        case .later: "Later"
        }
    }
}
