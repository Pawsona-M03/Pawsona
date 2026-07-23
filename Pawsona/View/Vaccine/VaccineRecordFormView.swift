//
//  VaccineRecordFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI
import UIKit

struct VaccineRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dog.name) private var dogs: [Dog]

    let title: String
    /// Supplied only when editing. Its presence is what puts the delete button
    /// on screen, so the add form stays exactly as it was.
    let onDelete: (() -> Void)?
    let onSave: (VaccineRecordDraft) -> Void

    @State private var vaccines: [VaccineType]
    @State private var selectedDogIDs: Set<UUID>
    @State private var dateGiven: Date
    @State private var notes: String

    /// `onDelete` sits ahead of `onSave` so a trailing-closure call still binds
    /// to `onSave`.
    init(
        title: String = "New Vaccination Record",
        draft: VaccineRecordDraft = VaccineRecordDraft(),
        onDelete: (() -> Void)? = nil,
        onSave: @escaping (VaccineRecordDraft) -> Void
    ) {
        self.title = title
        self.onDelete = onDelete
        self.onSave = onSave
        self._vaccines = State(initialValue: draft.vaccines)
        self._selectedDogIDs = State(initialValue: Set(draft.dogs.map(\.id)))
        self._dateGiven = State(initialValue: draft.dateGiven)
        self._notes = State(initialValue: draft.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VaccineTypeSection(selected: $vaccines)
                    VaccineDateSection(dateGiven: $dateGiven)
                    VaccineDogSection(dogs: dogs, selectedDogIDs: $selectedDogIDs)
                    VaccineNotesSection(notes: $notes)

                    if let onDelete {
                        DeleteConfirmationButton(
                            title: "Delete Record",
                            message: """
                                This removes the record from every dog it's \
                                assigned to. You can't undo this.
                                """
                        ) {
                            onDelete()
                            dismiss()
                        }
                        .cardBackground()
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .background(Color(.appBackground).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                        .buttonStyle(.glassProminent)
                        .tint(.gray)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: saveVaccineRecord)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
                        .disabled(!isSaveEnabled)
                }
            }
        }
    }

    // A dog is deliberately not required: a scan produces records before the user
    // has said which dog they belong to, and the record card flags the gap.
    private var isSaveEnabled: Bool {
        !vaccines.isEmpty
    }

    private var selectedDogs: [Dog] {
        dogs.filter { selectedDogIDs.contains($0.id) }
    }

    private func saveVaccineRecord() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(
            VaccineRecordDraft(
                vaccines: vaccines,
                dateGiven: dateGiven,
                dogs: selectedDogs,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
        )
        dismiss()
    }
}

private struct VaccineTypeSection: View {
    @Binding var selected: [VaccineType]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vaccine")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 2) {
                ForEach(VaccineType.allCases, id: \.self) { vaccine in
                    VaccineSelectionButton(
                        vaccine: vaccine,
                        isSelected: selected.contains(vaccine),
                        action: { toggle(vaccine) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .cardBackground()
        }
    }

    private func toggle(_ vaccine: VaccineType) {
        if let index = selected.firstIndex(of: vaccine) {
            selected.remove(at: index)
        } else {
            selected.append(vaccine)
        }
    }
}

private struct VaccineDateSection: View {
    @Binding var dateGiven: Date

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Date")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()

            DatePicker(
                "Vaccination date",
                selection: $dateGiven,
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()

            DatePicker(
                "Vaccination time",
                selection: $dateGiven,
                in: ...Date.now,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
        // Reads as one form row — label left, pickers right, on white — the way
        // the reminder sheet's date row does.
        .padding(.horizontal)
        .padding(.vertical, 12)
        .cardBackground()
    }
}

private struct VaccineDogSection: View {
    let dogs: [Dog]
    @Binding var selectedDogIDs: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Dog")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                if selectedDogIDs.isEmpty {
                    Label("Not assigned yet", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .labelStyle(.titleAndIcon)
                }
            }

            if dogs.isEmpty {
                ContentUnavailableView(
                    "No Dogs Yet",
                    systemImage: "pawprint",
                    description: Text("You can save this record now and assign a dog once you add one.")
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 5)], alignment: .leading, spacing: 8) {
                    ForEach(dogs, id: \.id) { dog in
                        VaccineDogSelectionButton(
                            dog: dog,
                            isSelected: selectedDogIDs.contains(dog.id),
                            action: { toggle(dog) }
                        )
                    }
                }
                .padding()
                .cardBackground()
            }
        }
    }

    private func toggle(_ dog: Dog) {
        if selectedDogIDs.contains(dog.id) {
            selectedDogIDs.remove(dog.id)
        } else {
            selectedDogIDs.insert(dog.id)
        }
    }
}

/// The form carried a `notes` value through save from the beginning, but had no
/// field for it — so a record's notes could round-trip on edit yet never be
/// written in the first place.
private struct VaccineNotesSection: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            TextField(
                "Vet, batch number, how they reacted…",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textInputAutocapitalization(.sentences)
            .padding()
            .cardBackground()
            .accessibilityLabel("Notes")
        }
    }
}

private struct VaccineSelectionButton: View {
    let vaccine: VaccineType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(vaccine.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color(.primaryBrown) : Color.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct VaccineDogSelectionButton: View {
    let dog: Dog
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                avatar
                    .overlay {
                        Circle()
                            .stroke(isSelected ? Color(.primaryBrown) : Color.clear, lineWidth: 3)
                    }

                Text(dog.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 58)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 58, minHeight: 78)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var avatar: some View {
        if let image = DogPhotoCache.image(for: dog) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(.circle)
        } else {
            Circle()
                .fill(.secondary.opacity(0.14))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary.opacity(0.28))
                }
        }
    }
}

#Preview("New") {
    VaccineRecordFormView { _ in }
        .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}

#Preview("Edit") {
    VaccineRecordFormView(
        title: "Edit Vaccination Record",
        draft: VaccineRecordDraft(vaccines: [.rabies], notes: "Given at the clinic on Jalan Raya."),
        onDelete: {},
        onSave: { _ in }
    )
    .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}
