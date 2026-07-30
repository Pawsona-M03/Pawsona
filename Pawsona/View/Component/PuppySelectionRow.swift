//
//  PuppySelectionRow.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 17/07/26.
//

import SwiftUI

/// A selectable puppy avatar in the reminder and vaccine forms' Dog grids.
/// Selection is shown as an orange ring around the photo, per the hifi.
struct PuppySelectionRow: View {
    let dog: Dog
    let isSelected: Bool
    let toggle: () -> Void

    @ScaledMetric private var avatarSize = 64

    private var displayName: String {
        guard dog.displayName.count > 5 else {
            return dog.displayName
        }

        return "\(dog.displayName.prefix(5))..."
    }

    var body: some View {
        Button(action: toggle) {
            VStack {
                DogPhotoView(dog: dog, placeholderIconHeight: avatarSize / 2)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(.circle)
                    .overlay {
                        if isSelected {
                            Circle().strokeBorder(Color(.primaryBrown), lineWidth: 3)
                        }
                    }

                Text(displayName)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dog.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
