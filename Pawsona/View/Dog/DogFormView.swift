//
//  DogFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct DogFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (DogDraft) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var dateOfBirth: Date
    @State private var backgroundColor: ColorType
    @State private var photoData: Data?
    @State private var photoSelection: PhotosPickerItem?

    init(
        title: String = "Add Dog",
        draft: DogDraft = DogDraft(),
        onSave: @escaping (DogDraft) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._name = State(initialValue: draft.name)
        self._breed = State(initialValue: draft.breed)
        self._dateOfBirth = State(initialValue: draft.dateOfBirth)
        self._backgroundColor = State(initialValue: draft.backgroundColor)
        self._photoData = State(initialValue: draft.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    PhotosPicker(selection: $photoSelection, matching: .images) {
                        photoPickerLabel
                    }
                    .accessibilityLabel(photoData == nil ? "Add dog photo" : "Change dog photo")
                    .accessibilityValue(photoData == nil ? "No photo selected" : "Photo selected")

                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Dog name")

                    TextField("Breed", text: $breed)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Dog breed")

                    DatePicker(
                        "Birthday",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )
                }

                Section("Card Color") {
                    Picker("Color", selection: $backgroundColor) {
                        ForEach(ColorType.allCases, id: \.self) { color in
                            DogColorPickerRow(color: color)
                                .tag(color)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                        .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveDog)
                        .disabled(trimmedBreed.isEmpty)
                        .accessibilityLabel("Save dog")
                        .accessibilityHint(
                            "Enter a breed before saving",
                            isEnabled: trimmedBreed.isEmpty
                        )
                }
            }
            .onChange(of: photoSelection) { _, newSelection in
                loadPhoto(from: newSelection)
            }
        }
    }

    @ViewBuilder
    private var photoPickerLabel: some View {
        HStack {
            if let photoData, let image = Image(data: photoData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(.circle)
            } else {
                Image(systemName: "photo.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }

            Text(photoData == nil ? "Add Photo" : "Change Photo")
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadPhoto(from selection: PhotosPickerItem?) {
        guard let selection else {
            return
        }

        Task {
            do {
                guard let loadedPhotoData = try await selection.loadTransferable(type: Data.self) else {
                    AccessibilityNotification.Announcement("Unable to load dog photo").post()
                    return
                }

                photoData = loadedPhotoData
                AccessibilityNotification.Announcement("Dog photo selected").post()
            } catch {
                AccessibilityNotification.Announcement("Unable to load dog photo").post()
            }
        }
    }

    private func saveDog() {
        onSave(
            DogDraft(
                name: trimmedName,
                breed: trimmedBreed,
                dateOfBirth: dateOfBirth,
                backgroundColor: backgroundColor,
                photoData: photoData
            )
        )
        dismiss()
    }
}

#Preview {
    DogFormView { _ in }
}
