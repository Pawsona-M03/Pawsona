//
//  ReminderFormView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import SwiftData
import SwiftUI

/// Create or edit a reminder, matching the hifi form: title, notes, date and
/// time, Clock-style repeat days, a colored type menu, and a puppy avatar
/// multi-select. Saving persists and (re)schedules notifications via
/// `ReminderFormViewModel`.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dog.name) private var dogs: [Dog]
    @State private var viewModel: ReminderFormViewModel
    private let navigationTitle: String

    /// The service is required rather than defaulted: a default here quietly
    /// built a second instance, so the form's permission state could never
    /// match the one the reminders screen was showing a banner for.
    init(
        editing reminder: Reminder? = nil,
        notificationService: NotificationService
    ) {
        if let reminder {
            _viewModel = State(
                initialValue: ReminderFormViewModel(editing: reminder, notificationService: notificationService)
            )
            navigationTitle = "Edit Reminder"
        } else {
            _viewModel = State(
                initialValue: ReminderFormViewModel(notificationService: notificationService)
            )
            navigationTitle = "Add New Reminder"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $viewModel.title)
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                }

                Section {
                    DatePicker(
                        "Date",
                        selection: $viewModel.dueDate,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    LabeledContent("Repeat", value: viewModel.repeatSummary)
                    RepeatDayPicker(selectedDays: $viewModel.repeatDays)
                }

                Section {
                    LabeledContent("Type") {
                        ReminderTypePicker(selection: $viewModel.category)
                    }
                }

                if !dogs.isEmpty {
                    Section("Dog") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], alignment: .leading) {
                            ForEach(dogs) { dog in
                                PuppySelectionRow(dog: dog, isSelected: viewModel.isSelected(dog)) {
                                    viewModel.toggleDog(dog)
                                }
                            }
                        }
                    }
                }

                if viewModel.isEditing {
                    Section {
                        DeleteConfirmationButton(
                            title: "Delete Reminder",
                            message: "This also cancels its notification. You can't undo this.",
                            action: delete
                        )
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                        .buttonStyle(.glassProminent)
                        .tint(.gray)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: save)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
                        .disabled(!viewModel.isSaveEnabled)
                }
            }
        }
    }

    private func delete() {
        viewModel.delete(in: modelContext)
        dismiss()
    }

    private func save() {
        Task {
            await viewModel.save(in: modelContext)
            dismiss()
        }
    }
}

#Preview("Add") {
    ReminderFormView(notificationService: NotificationService())
        .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
}

#Preview("Edit") {
    ReminderFormView(
        editing: Reminder(
            title: "Vitamin A",
            notes: "1 sendok makan, 2 kali sehari",
            dueDate: .now,
            repeatDays: [2, 4, 6],
            category: .vitamin
        ),
        notificationService: NotificationService()
    )
    .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
}
