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

    /// Form rows grow with Dynamic Type rather than clipping at a fixed 60pt.
    @ScaledMetric(relativeTo: .body) private var rowHeight = 60

    @State private var name: String
    @State private var breed: String
    @State private var dateOfBirth: Date
    @State private var backgroundColor: ColorType
    @State private var weightText: String
    @State private var sex: Sex?
    @State private var photoData: Data?

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

                // No explicit spacing: each button spreads to an equal share of
                // the width instead, which is what buys the 44pt hit target
                // without eight fixed 44pt boxes overflowing the screen.
                HStack(spacing: 0) {
                    ForEach(ColorType.allCases, id: \.self) { color in
                        Button {
                            backgroundColor = color
                        } label: {
                            DogColorPickerRow(
                                color: color,
                                isSelected: backgroundColor == color
                            )
                            .frame(width: 17, height: 17)
                            // The swatch stays 17pt to match the hifi; the
                            // button around it is what has to clear 44x44pt.
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.accessibilityName)
                        .accessibilityAddTraits(
                            backgroundColor == color ? .isSelected : []
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 16)
                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        if breed.isEmpty {
                            HStack(spacing: 2) {
                                Text("Breed")
                                    .foregroundStyle(.secondary)
                                Text("*")
                                    .foregroundStyle(.red)
                            }
                            .allowsHitTesting(false)
                        }

                        TextField("", text: $breed)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Dog breed")
                    }
                    .frame(minHeight: rowHeight)

                    Divider()

                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Dog name")
                        .frame(minHeight: rowHeight)

                    Divider()

                    Menu {
                        Button("Male") {
                            sex = .male
                        }

                        Button("Female") {
                            sex = .female
                        }

                        Button("Not Set") {
                            sex = nil
                        }
                    } label: {
                        HStack {
                            Text(sex.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .frame(minHeight: rowHeight)
                        .contentShape(.rect)
                    }
                    .accessibilityLabel("Dog gender")

                    Divider()

                    DatePicker(
                        "Date of Birth",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )
                    .frame(minHeight: rowHeight)

                    Divider()

                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Dog weight")
                        .frame(minHeight: rowHeight)
                }
                .padding(.horizontal, 14)
                .cardBackground(cornerRadius: 32)
                .padding(.horizontal, 30)

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
            .background {
                Color(.appBackground)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        "Close",
                        systemImage: "xmark",
                        action: dismiss.callAsFunction
                    )
                    .buttonStyle(.glassProminent)
                    .tint(.gray)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle, systemImage: "checkmark", action: saveDog)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
                        .disabled(trimmedBreed.isEmpty)
                        .accessibilityHint(
                            "Enter a breed before saving",
                            isEnabled: trimmedBreed.isEmpty
                        )
                }
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

private extension Optional where Wrapped == Sex {
    var displayName: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        case nil:
            "Gender"
        }
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
