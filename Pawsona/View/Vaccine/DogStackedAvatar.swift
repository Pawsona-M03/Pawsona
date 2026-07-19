//
//  DogStackedAvatar.swift
//  Pawsona
//

import SwiftUI

/// A small circular dog photo to be displayed stacked (overlapping) in VaccineRecordGroupRowView.
struct DogStackedAvatar: View {
    let dog: Dog

    private let avatarDiameter: CGFloat = 32
    private var stackOverlap: CGFloat { avatarDiameter / 16 }

    var body: some View {
        DogAvatarImage(dog: dog)
            .frame(width: avatarDiameter, height: avatarDiameter)
            .clipShape(.circle)
            .overlay(Circle().stroke(.background, lineWidth: stackOverlap))
    }
}

#Preview {
    DogStackedAvatar(dog: Dog(name: "Nathan"))
}
