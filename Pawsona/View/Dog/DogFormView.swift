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
    let onSave: (DogProfile) -> Void

    @State private var profile: DogProfile
    @State private var photoSelection: PhotosPickerItem?

    init(
        title: String = "Add Dog",
        profile: DogProfile = DogProfile(),
        onSave: @escaping (DogProfile) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._profile = State(initialValue: profile)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    PhotosPicker(selection: $photoSelection, matching: .images) {
                        photoPickerLabel
                    }

                    TextField("Name", text: $profile.name)
                        .textInputAutocapitalization(.words)

                    TextField("Breed", text: $profile.breed)
                        .textInputAutocapitalization(.words)

                    DatePicker(
                        "Birthday",
                        selection: $profile.dateOfBirth,
                        displayedComponents: .date
                    )
                }

                Section("Card Color") {
                    Picker("Color", selection: $profile.backgroundColor) {
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
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveDog)
                        .disabled(trimmedBreed.isEmpty)
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
            if let photoData = profile.photoData, let image = Image(data: photoData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(.circle)
            } else {
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }

            Text(profile.photoData == nil ? "Add Photo" : "Change Photo")
        }
    }

    private var trimmedName: String {
        profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        profile.breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadPhoto(from selection: PhotosPickerItem?) {
        Task {
            profile.photoData = try? await selection?.loadTransferable(type: Data.self)
        }
    }

    private func saveDog() {
        var savedProfile = profile
        savedProfile.name = trimmedName
        savedProfile.breed = trimmedBreed
        onSave(savedProfile)
        dismiss()
    }
}

#Preview {
    DogFormView { _ in }
}
