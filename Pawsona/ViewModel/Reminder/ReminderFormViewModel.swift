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
    var repeatDays: Set<Int>
    var selectedDogs: [Dog]
    var errorMessage: String?

    private let editingReminder: Reminder?
    private let notificationService: NotificationService

    /// New reminder. Defaults the due date one hour ahead so a freshly typed
    /// title is immediately saveable.
    init(notificationService: NotificationService) {
        self.title = ""
        self.category = .others
        self.dueDate = Date.now.addingTimeInterval(3600)
        self.notes = ""
        self.repeatDays = []
        self.selectedDogs = []
        self.editingReminder = nil
        self.notificationService = notificationService
    }

    /// Edit an existing reminder — pre-fills every field from it.
    init(editing reminder: Reminder, notificationService: NotificationService) {
        self.title = reminder.title
        self.category = reminder.category
        self.dueDate = reminder.dueDate
        self.notes = reminder.notes ?? ""
        self.repeatDays = Set(reminder.repeatDays)
        self.selectedDogs = reminder.dogList ?? []
        self.editingReminder = reminder
        self.notificationService = notificationService
    }

    /// A repeating reminder fires weekly regardless of its start date, so only
    /// one-shots require a future due date.
    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!repeatDays.isEmpty || dueDate > .now)
    }

    /// Deleting only makes sense for a reminder that already exists.
    var isEditing: Bool { editingReminder != nil }

    /// What the form's Repeat row shows next to the label.
    var repeatSummary: String {
        Reminder.repeatSummary(for: repeatDays) ?? "Never"
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

    /// Removes the reminder being edited, cancelling its pending notification
    /// first so nothing fires for a reminder that no longer exists.
    func delete(in modelContext: ModelContext) {
        guard let editingReminder else { return }

        notificationService.cancel(editingReminder)
        modelContext.delete(editingReminder)

        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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
            editingReminder.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            editingReminder.repeatDays = repeatDays.sorted()
            editingReminder.dogList = selectedDogs
            reminder = editingReminder
        } else {
            reminder = Reminder(
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                dogList: selectedDogs,
                dueDate: dueDate,
                repeatDays: repeatDays.sorted(),
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

        await notificationService.schedule(reminder)
        return reminder
    }
}


