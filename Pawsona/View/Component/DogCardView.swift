//
//  DogCardView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI
import UIKit

struct DogCardView: View {
    let dog: Dog

    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 211
    @ScaledMetric(relativeTo: .largeTitle) private var placeholderIconSize = 128

    var body: some View {
        VStack(spacing: 8) {
            photo
                .frame(width: .infinity)
                .frame(height: cardHeight * 0.75)
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
        .frame(width: 162)
        .background(.background)
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var photo: some View {
        if let photoData = dog.photoData, let image = Image(data: photoData) {
            image
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(dog.backgroundColor.color.opacity(0.2))
                .overlay(alignment: .bottom) {
                    Image(.dogPlaceholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: placeholderIconSize)
                }
        }
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

private extension Image {
    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
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
