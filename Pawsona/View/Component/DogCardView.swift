//
//  DogCardView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct DogCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let dog: Dog

    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 211

    private var photoHeight: CGFloat { cardHeight * 0.75 }

    var body: some View {
        VStack(spacing: 8) {
            DogPhotoView(dog: dog, placeholderIconHeight: photoHeight * 0.6)
                .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 162)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                .frame(height: photoHeight)
                .clipped()

            VStack(alignment: .center, spacing: 4) {
                Text("\(displayName)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary).lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 162)
        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
        .background(Color(.cardSurface))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var breedText: String {
        dog.breed.isEmpty ? "Breed not set" : dog.breed
    }

    private var ageText: String? {
        guard let age = dog.age else { return nil }
        return age == 1 ? "1 year old" : "\(age) years old"
    }

    private var accessibilityLabel: String {
        var label = "\(displayName), \(breedText)"
        if let ageText {
            label += ", \(ageText)"
        }
        return label
    }
}

#Preview {
    DogCardView(
        dog: Dog(
            name: "Berry",
            breed: "Labrador Retriever",
            backgroundColor: .green,
        )
    )
    .padding()
}
