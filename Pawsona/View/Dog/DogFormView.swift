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
    @State private var weightText: String
    @State private var sex: Sex?
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
        self._weightText = State(
            initialValue: draft.weightKg?.formatted(.number.precision(.fractionLength(1))) ?? ""
        )
        self._sex = State(initialValue: draft.sex)
        self._photoData = State(initialValue: draft.photoData)
    }

    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $photoSelection, matching: .images) {
                    photoPickerLabel
                }
                .padding(.bottom, 30)
                .accessibilityLabel(
                    photoData == nil ? "Add dog photo" : "Change dog photo"
                )
                .accessibilityValue(
                    photoData == nil ? "No photo selected" : "Photo selected"
                )

                HStack(spacing: 10) {
                    ForEach(ColorType.allCases, id: \.self) { color in
                        Button {
                            backgroundColor = color
                        } label: {
                            DogColorPickerRow(
                                color: color,
                                isSelected: backgroundColor == color
                            )
                            .frame(width: 17, height: 17)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.accessibilityName)
                        .accessibilityAddTraits(
                            backgroundColor == color ? .isSelected : []
                        )
                    }
                }.padding(.bottom, 16)
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
                    .frame(height: 60)

                    Divider()

                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Dog name")
                        .frame(height: 60)

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
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        .frame(height: 60)
                    }
                    .accessibilityLabel("Dog gender")

                    Divider()

                    DatePicker(
                        "Date of Birth",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )
                    .frame(height: 60)

                    Divider()

                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Dog weight")
                        .frame(height: 60)
                }
                .padding(.horizontal, 14)
                .cardBackground(cornerRadius: 32)
                .padding(.horizontal, 30)
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
                        "Cancel",
                        systemImage: "xmark",
                        action: dismiss.callAsFunction
                    )
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Dog", systemImage: "checkmark", action: saveDog)
                        .buttonStyle(.glassProminent)
                        .tint(Color(.primaryBrown))
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
        Group {
            if let photoData, let image = Image(data: photoData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
            } else {
                Rectangle()
                    .fill(backgroundColor.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .overlay(alignment: .bottom) {
                        Image(.dogPlaceholder)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                    }
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "pencil")
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(.primaryBrown), in: .circle)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedWeightKg: Double? {
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedWeight.isEmpty ? nil : Double(trimmedWeight)
    }

    private func loadPhoto(from selection: PhotosPickerItem?) {
        guard let selection else {
            return
        }

        Task {
            do {
                guard
                    let loadedPhotoData = try await selection.loadTransferable(
                        type: Data.self
                    )
                else {
                    AccessibilityNotification.Announcement(
                        "Unable to load dog photo"
                    ).post()
                    return
                }

                photoData = loadedPhotoData
                AccessibilityNotification.Announcement("Dog photo selected")
                    .post()
            } catch {
                AccessibilityNotification.Announcement(
                    "Unable to load dog photo"
                ).post()
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

extension ColorType {
    fileprivate var accessibilityName: String {
        switch self {
        case .red:
            "Red"
        case .orange:
            "Orange"
        case .yellow:
            "Yellow"
        case .green:
            "Green"
        case .blue:
            "Blue"
        case .purple:
            "Purple"
        case .pink:
            "Pink"
        case .gray:
            "Gray"
        }
    }
}

#Preview {
    DogFormView { _ in }
}
