//
//  ReminderRowView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import SwiftUI

/// A reminder card for the day list: type icon and title in the type's color,
/// the due date-time (or "Every …" for repeats), notes, and linked puppies.
struct ReminderRowView: View {
    let reminder: Reminder

    @ScaledMetric(relativeTo: .title3) private var iconWidth = 32
    @ScaledMetric private var avatarSize = 56

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: reminder.category.icon)
                .font(.title3)
                .foregroundStyle(reminder.category.color)
                .frame(width: iconWidth)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let repeatSummary = reminder.repeatSummary {
                    Text(repeatSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                if let dogs = reminder.dogList, !dogs.isEmpty {
                    HStack(alignment: .top) {
                        ForEach(dogs) { dog in
                            VStack {
                                DogPhotoView(dog: dog, placeholderIconHeight: avatarSize / 2)
                                    .frame(width: avatarSize, height: avatarSize)
                                    .clipShape(.circle)
                                Text(dog.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(reminder.title), \(reminder.category.displayName)"
        if let repeatSummary = reminder.repeatSummary {
            label += ", repeats \(repeatSummary)"
        } else {
            label += ", due \(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))"
        }
        if let notes = reminder.notes, !notes.isEmpty { label += ", \(notes)" }
        if let puppyNames { label += ", for \(puppyNames)" }
        return label
    }

    private var puppyNames: String? {
        let names = (reminder.dogList ?? []).compactMap {
            $0.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }
}
