//
//  DogCardView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI
import UIKit

struct DogCardView: View {
    let dog: Dog

    var body: some View {
        HStack {
            avatar
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dog.breed.isEmpty ? "Breed not set" : dog.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(birthdayText)
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

    @ViewBuilder
    private var avatar: some View {
        if let photoData = dog.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(.circle)
        } else {
            Circle()
                .fill(backgroundStyle)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Unnamed Dog" : trimmedName
    }

    private var birthdayText: String {
        guard let dateOfBirth = dog.dateOfBirth else {
            return "Birthday not set"
        }

        return dateOfBirth.formatted(date: .abbreviated, time: .omitted)
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

        guard let dateOfBirth = dog.dateOfBirth else {
            return "\(displayName), \(breed), birthday not set"
        }

        let birthDate = dateOfBirth.formatted(date: .abbreviated, time: .omitted)
        return "\(displayName), \(breed), born \(birthDate)"
    }
}

#Preview {
    DogCardView(
        dog: Dog(
            name: "Nathan",
            breed: "Samoyed",
            backgroundColor: .blue,
            dateOfBirth: Date.now
        )
    )
    .padding()
}
