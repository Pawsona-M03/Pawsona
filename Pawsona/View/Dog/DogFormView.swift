//
//  DogFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

struct DogFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let saveTitle: String
    /// Supplied only when editing. Its presence is what puts the delete button
    /// on screen, so the add form stays exactly as it was.
    let onDelete: (() -> Void)?
    let onSave: (DogDraft) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var dateOfBirth: Date
    @State private var backgroundColor: ColorType
    @State private var weightText: String
    @State private var sex: Sex?
    @State private var photoData: Data?
    @State private var isShowingCancelConfirmation = false
    @State private var hasAttemptedSave = false

    /// `onDelete` sits ahead of `onSave` so the add form's trailing-closure call
    /// still binds to `onSave`.
    init(
        title: String = "Add Dog",
        saveTitle: String = "Add Dog",
        draft: DogDraft = DogDraft(),
        onDelete: (() -> Void)? = nil,
        onSave: @escaping (DogDraft) -> Void
    ) {
        self.title = title
        self.saveTitle = saveTitle
        self.onDelete = onDelete
        self.onSave = onSave
        self._name = State(initialValue: draft.name)
        self._breed = State(initialValue: draft.breed)
        self._dateOfBirth = State(initialValue: draft.dateOfBirth)
        self._backgroundColor = State(initialValue: draft.backgroundColor)
        self._weightText = State(initialValue: DogDraft.weightText(for: draft.weightKg))
        self._sex = State(initialValue: draft.sex)
        self._photoData = State(initialValue: draft.photoData)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DogPhotoPickerButton(
                    photoData: $photoData,
                    backgroundColor: backgroundColor
                )
                .padding(.bottom, 30)

                DogFormColorPickerView(backgroundColor: $backgroundColor)
//                    .padding(.horizontal, 30)

                DogFormFieldsView(
                    name: $name,
                    breed: $breed,
                    dateOfBirth: $dateOfBirth,
                    weightText: $weightText,
                    sex: $sex,
                    showsBreedValidationError: hasAttemptedSave && trimmedBreed.isEmpty
                )

                if let onDelete {
                    DeleteConfirmationButton(
                        title: "Delete Dog",
                        message: """
                            This doesn't delete their vaccination records or \
                            reminders — those stay, unassigned. You can't undo \
                            this.
                            """
                    ) {
                        onDelete()
                        dismiss()
                    }
                    // Matches the form card above it rather than the reminder
                    // sheet's tighter radius: within one screen the corners
                    // agreeing matters more than they do across screens.
                    .cardBackground(cornerRadius: 32)
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.appBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        "Close",
                        systemImage: "xmark"
                    ) {
                        isShowingCancelConfirmation = true
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.gray)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle, systemImage: "checkmark", action: saveDog)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
                        .accessibilityHint(
                            "Enter a breed before saving",
                            isEnabled: trimmedBreed.isEmpty
                    )
                }
            }
            .alert("Discard Changes?", isPresented: $isShowingCancelConfirmation) {
                Button("Discard Changes", role: .destructive, action: dismiss.callAsFunction)
                Button("Keep Editing", role: .cancel) {}
                    .tint(.primary)
            } message: {
                Text("Your changes won't be saved.")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedWeightKg: Double? {
        DogDraft.weightKg(fromText: weightText)
    }

    private func saveDog() {
        guard !trimmedBreed.isEmpty else {
            hasAttemptedSave = true
            return
        }

        onSave(
            DogDraft(
                name: trimmedName,
                breed: trimmedBreed,
                dateOfBirth: dateOfBirth,
                backgroundColor: backgroundColor,
                weightKg: parsedWeightKg,
                sex: sex,
                photoData: photoData
            )
        )
        dismiss()
    }
}

#Preview("Add") {
    DogFormView { _ in }
}

#Preview("Edit") {
    DogFormView(
        title: "Edit Dog",
        saveTitle: "Save",
        draft: DogDraft(
            name: "Berry",
            breed: "Labrador Retriever",
            weightKg: 12.4,
            sex: .female
        ),
        onDelete: {},
        onSave: { _ in }
    )
}
