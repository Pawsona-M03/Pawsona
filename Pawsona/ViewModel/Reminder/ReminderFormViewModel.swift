//
//  ReminderFormViewModel.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import Foundation
import Observation
import SwiftData

/// Backs the create/edit reminder form: holds the editable fields, gates saving,
/// and persists + (re)schedules the reminder's notification on save.
@Observable
final class ReminderFormViewModel {
    var title: String
    var category: ReminderType
    var dueDate: Date
    var notes: String
    var selectedDogs: [Dog]
    var repeatRule: RepeatRule?
    var errorMessage: String?

    var repeatUnit: RepeatUnit? {
        get { repeatRule?.unit }
        set {
            if let newValue {
                repeatRule = RepeatRule(interval: 1, unit: newValue)
            } else {
                repeatRule = nil
            }
        }
    }

    private let editingReminder: Reminder?
    private let notificationService: NotificationService

    /// New reminder. Defaults the due date one hour ahead so a freshly typed
    /// title is immediately saveable.
    init(notificationService: NotificationService) {
        self.title = ""
        self.category = .others
        self.dueDate = Date.now.addingTimeInterval(3600)
        self.notes = ""
        self.selectedDogs = []
        self.repeatRule = nil
        self.editingReminder = nil
        self.notificationService = notificationService
    }

    /// Edit an existing reminder — pre-fills every field from it.
    init(editing reminder: Reminder, notificationService: NotificationService) {
        self.title = reminder.title
        self.category = reminder.category
        self.dueDate = reminder.dueDate
        self.notes = reminder.notes ?? ""
        self.selectedDogs = reminder.dogList ?? []
        self.repeatRule = reminder.repeatRule
        self.editingReminder = reminder
        self.notificationService = notificationService
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dueDate > .now
    }

    func toggleDog(_ dog: Dog) {
        if let index = selectedDogs.firstIndex(where: { $0.id == dog.id }) {
            selectedDogs.remove(at: index)
        } else {
            selectedDogs.append(dog)
        }
    }

    func isSelected(_ dog: Dog) -> Bool {
        selectedDogs.contains { $0.id == dog.id }
    }

    /// Persists the reminder and (re)schedules its notification. Editing cancels
    /// the old notification before scheduling the replacement.
    @discardableResult
    func save(in modelContext: ModelContext) async -> Reminder? {
        guard isSaveEnabled else { return nil }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let reminder: Reminder
        if let editingReminder {
            notificationService.cancel(editingReminder)
            editingReminder.title = trimmedTitle
            editingReminder.category = category
            editingReminder.dueDate = dueDate
            editingReminder.repeatRule = repeatRule
            editingReminder.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            editingReminder.dogList = selectedDogs
            reminder = editingReminder
        } else {
            reminder = Reminder(
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                dogList: selectedDogs,
                dueDate: dueDate,
                repeatRule: repeatRule,
                category: category
            )
            modelContext.insert(reminder)
        }

        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        do {
            try await notificationService.schedule(reminder)
        } catch {
            if errorMessage == nil {
                errorMessage = "Reminder saved, but scheduling the notification failed: \(error.localizedDescription)"
            }
        }

        return reminder
    }
}
