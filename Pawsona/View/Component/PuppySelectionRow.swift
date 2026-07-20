//
//  PuppySelectionRow.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import SwiftUI

/// A selectable puppy avatar in the reminder form's Dog grid. Selection is
/// shown as an orange ring around the photo, per the hifi.
struct PuppySelectionRow: View {
    let dog: Dog
    let isSelected: Bool
    let toggle: () -> Void

    @ScaledMetric private var avatarSize = 64

    var body: some View {
        Button(action: toggle) {
            VStack {
                DogPhotoView(dog: dog, placeholderIconHeight: avatarSize / 2)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(.circle)
                    .overlay {
                        if isSelected {
                            Circle().strokeBorder(.orange, lineWidth: 3)
                        }
                    }

                Text(dog.name ?? "Puppy")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dog.name ?? "Puppy")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
