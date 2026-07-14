//
//  DogCardView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

struct DogCardView: View {
    let dog: Dog

    var body: some View {
        HStack {
            Circle()
                .fill(backgroundStyle)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dog.breed.isEmpty ? "Breed not set" : dog.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(dog.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Unnamed Dog" : trimmedName
    }

    private var backgroundStyle: Color {
        switch dog.backgroundColor {
        case .red:
            .red
        case .orange:
            .orange
        case .yellow:
            .yellow
        case .green:
            .green
        case .blue:
            .blue
        case .purple:
            .purple
        case .pink:
            .pink
        case .gray:
            .gray
        }
    }

    private var accessibilityLabel: String {
        let breed = dog.breed.isEmpty ? "Breed not set" : dog.breed
        let birthDate = dog.dateOfBirth.formatted(date: .abbreviated, time: .omitted)
        return "\(displayName), \(breed), born \(birthDate)"
    }
}

#Preview {
    DogCardView(
        dog: Dog(
            name: "Nathan",
            breed: "Samoyed",
            dateOfBirth: Date.now,
            backgroundColor: .blue
        )
    )
    .padding()
}
