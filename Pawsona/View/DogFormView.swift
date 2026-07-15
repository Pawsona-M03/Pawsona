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
    let onSave: (String, String, Date, ColorType, Data?) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var dateOfBirth: Date
    @State private var backgroundColor: ColorType
    @State private var photoData: Data?
    @State private var photoSelection: PhotosPickerItem?

    init(
        title: String = "Add Dog",
        name: String = "",
        breed: String = "",
        dateOfBirth: Date = Date.now,
        backgroundColor: ColorType = .blue,
        photoData: Data? = nil,
        onSave: @escaping (String, String, Date, ColorType, Data?) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._name = State(initialValue: name)
        self._breed = State(initialValue: breed)
        self._dateOfBirth = State(initialValue: dateOfBirth)
        self._backgroundColor = State(initialValue: backgroundColor)
        self._photoData = State(initialValue: photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    PhotosPicker(selection: $photoSelection, matching: .images) {
                        photoPickerLabel
                    }

                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Breed", text: $breed)
                        .textInputAutocapitalization(.words)

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
            if let photoData, let image = Image(data: photoData) {
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
        Task {
            photoData = try? await selection?.loadTransferable(type: Data.self)
        }
    }

    private func saveDog() {
        onSave(trimmedName, trimmedBreed, dateOfBirth, backgroundColor, photoData)
        dismiss()
    }
}

private extension Image {
    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
    }
}

#Preview {
    DogFormView { _, _, _, _, _ in }
}
