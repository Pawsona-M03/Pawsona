//
//  UpcomingRemindersView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 19/07/26.
//

import SwiftData
import SwiftUI

/// The reminders home screen: a week strip to pick a day, that day's reminder
/// cards, and the create/edit form. Matches the hifi's calendar-per-day layout.
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
            List {
                Group {
                    WeekStripView(days: viewModel.weekDays(), selectedDate: $viewModel.selectedDate)

                    Text(viewModel.selectedDate.formatted(
                        .dateTime.weekday(.wide).day().month(.wide).year()
                    ))
                    .font(.title3)
                    .bold()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if dayReminders.isEmpty {
                    Text(emptyMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(dayReminders) { reminder in
                        Section {
                            Button {
                                editingReminder = reminder
                            } label: {
                                ReminderRowView(reminder: reminder)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    viewModel.delete(reminder, in: modelContext)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                Image(.pawsBg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .navigationTitle("Reminder")
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

    private var dayReminders: [Reminder] {
        viewModel.reminders(from: reminders, on: viewModel.selectedDate)
    }

    private var emptyMessage: String {
        Calendar.current.isDateInToday(viewModel.selectedDate)
            ? "No Reminder for Today"
            : "No Reminders"
    }
}

#Preview {
    UpcomingRemindersView()
        .modelContainer(for: [Dog.self, Reminder.self], inMemory: true)
        .tint(.brown)
}
