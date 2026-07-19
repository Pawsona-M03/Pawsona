//
//  ReminderFormView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import SwiftData
import SwiftUI

/// Create or edit a reminder: title, category, date-time, notes, and a
/// multi-select of puppies to link. Saving persists and (re)schedules its
/// notification via `ReminderFormViewModel`.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dog.name) private var dogs: [Dog]
    @State private var viewModel: ReminderFormViewModel
    private let navigationTitle: String

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
            navigationTitle = "New Reminder"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $viewModel.title)

                    Picker("Category", selection: $viewModel.category) {
                        ForEach(ReminderType.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }

                    DatePicker(
                        "Date & time",
                        selection: $viewModel.dueDate,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker("Repeat", selection: $viewModel.repeatUnit) {
                        Text("Never").tag(RepeatUnit?.none)
                        Text("Daily").tag(RepeatUnit?.some(.day))
                        Text("Weekly").tag(RepeatUnit?.some(.week))
                        Text("Monthly").tag(RepeatUnit?.some(.month))
                        Text("Yearly").tag(RepeatUnit?.some(.year))
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                }

                if !dogs.isEmpty {
                    Section("Puppies") {
                        ForEach(dogs) { dog in
                            PuppySelectionRow(dog: dog, isSelected: viewModel.isSelected(dog)) {
                                viewModel.toggleDog(dog)
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!viewModel.isSaveEnabled)
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.errorMessage ?? "")
            }
        )
    }

    private func save() {
        Task {
            await viewModel.save(in: modelContext)
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#Preview {
    ReminderFormView(notificationService: NotificationService())
        .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
}
