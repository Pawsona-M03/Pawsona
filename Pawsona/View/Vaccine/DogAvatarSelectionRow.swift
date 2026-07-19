//
//  DogAvatarSelectionRow.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftUI

/// A single selectable puppy avatar (multi-select), circular photo with name below it.
struct DogAvatarSelectionRow: View {
    let dog: Dog
    let isSelected: Bool
    let toggle: () -> Void

    private let avatarDiameter: CGFloat = 56
    private var selectionRingDiameter: CGFloat { avatarDiameter + 4 }

    var body: some View {
        Button(action: toggle) {
            VStack(spacing: 5) {
                ZStack {
                    DogAvatarImage(dog: dog)
                        .clipShape(.circle)
                        .frame(width: avatarDiameter, height: avatarDiameter)

                    if isSelected {
                        Circle()
                            .stroke(.tint, lineWidth: 3)
                            .frame(width: selectionRingDiameter, height: selectionRingDiameter)
                    }
                }

                Text(dog.name ?? "Puppy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    DogAvatarSelectionRow(dog: Dog(name: "Piere"), isSelected: true) {}
}
