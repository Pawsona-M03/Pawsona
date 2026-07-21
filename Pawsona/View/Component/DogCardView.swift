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
                Text(dog.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dog.breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary).lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 162)
        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
        .cardBackground()
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(dog.displayName), \(dog.breedText)"
        if let ageText = dog.ageText {
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
