//
//  ReminderRowView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import SwiftUI

/// A single reminder in the upcoming list: category icon, title, due time, and
/// the linked puppies. Overdue reminders show their due time in red.
struct ReminderRowView: View {
    let reminder: Reminder
    var isOverdue: Bool = false

    @ScaledMetric(relativeTo: .title3) private var iconWidth = 32

    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: iconWidth)

            VStack(alignment: .leading) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(isOverdue ? Color.red : Color.secondary)

                if let puppyNames {
                    Text(puppyNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var categoryIcon: String {
        switch reminder.category {
        case .medicine: "pills.fill"
        case .vitamin: "leaf.fill"
        case .vaccine: "syringe"
        case .others: "bell.fill"
        }
    }

    private var puppyNames: String? {
        let names = (reminder.dogList ?? []).compactMap {
            $0.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }

    private var accessibilityLabel: String {
        let due = reminder.dueDate.formatted(date: .abbreviated, time: .shortened)
        var label = "\(reminder.title), \(reminder.category.rawValue), due \(due)"
        if isOverdue { label += ", overdue" }
        if let puppyNames { label += ", for \(puppyNames)" }
        return label
    }
}
