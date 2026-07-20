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

    init(
        editing reminder: Reminder? = nil,
        notificationService: NotificationService = NotificationService()
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack {
                        TextField("Title", text: $viewModel.title)
                            .font(.title3)
                        Divider()
                        TextField("Notes", text: $viewModel.notes, axis: .vertical)
                            .font(.title3)
                        Divider()
                    }

                    HStack {
                        Text("Date")
                            .font(.title3)
                            .bold()
                        Spacer()
                        DatePicker(
                            "Date",
                            selection: $viewModel.dueDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        DatePicker(
                            "Time",
                            selection: $viewModel.dueDate,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text("Repeat")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text(viewModel.repeatSummary)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                        RepeatDayPicker(selectedDays: $viewModel.repeatDays)
                    }

                    HStack {
                        Text("Type")
                            .font(.title3)
                            .bold()
                        Spacer()
                        typeMenu
                    }

                    if !dogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dog")
                                .font(.title3)
                                .bold()
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], alignment: .leading) {
                                ForEach(dogs) { dog in
                                    PuppySelectionRow(dog: dog, isSelected: viewModel.isSelected(dog)) {
                                        viewModel.toggleDog(dog)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: save)
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.isSaveEnabled)
                }
            }
        }
    }

    private var typeMenu: some View {
        Menu {
            Picker("Type", selection: $viewModel.category) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: "circle.fill")
                        .tag(type)
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(viewModel.category.color)
                    .frame(width: 10, height: 10)
                Text(viewModel.category.displayName)
                    .font(.title3)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Type, \(viewModel.category.displayName)")
    }

    private func save() {
        Task {
            await viewModel.save(in: modelContext)
            dismiss()
        }
    }
}

#Preview {
    ReminderFormView()
        .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
        .tint(.brown)
}
