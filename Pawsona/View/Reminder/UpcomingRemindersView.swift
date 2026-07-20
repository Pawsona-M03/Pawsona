//
//  UpcomingRemindersView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import SwiftData
import SwiftUI

/// The reminders home screen: upcoming reminders grouped by how soon they are
/// due, with create/edit forms and swipe-to-delete.
struct UpcomingRemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reminder.dueDate) private var reminders: [Reminder]
    @State private var notificationService: NotificationService
    @State private var viewModel: UpcomingRemindersViewModel
    @State private var editingReminder: Reminder?
    @State private var isShowingNewReminderForm = false

    init() {
        // One service instance shared by the list (permission state, deletes) and
        // injected into the view model so cancel/schedule hit the same center.
        let service = NotificationService()
        _notificationService = State(initialValue: service)
        _viewModel = State(initialValue: UpcomingRemindersViewModel(notificationService: service))
    }

    var body: some View {
        NavigationStack {
            Group {
                if reminders.isEmpty {
                    ContentUnavailableView {
                        Label("No Reminders", systemImage: "bell")
                    } description: {
                        Text("Reminders you create will show up here, soonest first.")
                    } actions: {
                        Button("Create Reminder", systemImage: "plus") {
                            isShowingNewReminderForm = true
                        }
                    }
                } else {
                    reminderList
                }
            }
            .navigationTitle("Reminders")
            .safeAreaInset(edge: .top) {
                if notificationService.permissionState == .denied {
                    NotificationPermissionBanner()
                        .padding(.horizontal)
                }
            }
            .task {
                await notificationService.requestPermission()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Reminder", systemImage: "plus") {
                        isShowingNewReminderForm = true
                    }
                }
            }
            .sheet(isPresented: $isShowingNewReminderForm) {
                ReminderFormView()
            }
            .sheet(item: $editingReminder) { reminder in
                ReminderFormView(editing: reminder)
            }
        }
    }

    private var reminderList: some View {
        List {
            ForEach(viewModel.sections(for: reminders)) { section in
                Section(section.group.title) {
                    ForEach(section.reminders) { reminder in
                        Button {
                            editingReminder = reminder
                        } label: {
                            ReminderRowView(reminder: reminder, isOverdue: section.group == .overdue)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        delete(offsets, in: section.reminders)
                    }
                }
            }
        }
    }

    private func delete(_ offsets: IndexSet, in sectionReminders: [Reminder]) {
        for reminder in offsets.map({ sectionReminders[$0] }) {
            viewModel.delete(reminder, in: modelContext)
        }
    }
}

#Preview {
    UpcomingRemindersView()
        .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
}
