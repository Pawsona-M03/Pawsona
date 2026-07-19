//
//  DogAvatarImage.swift
//  Pawsona
//

import SwiftUI

struct DogAvatarImage: View {
    let dog: Dog

    var body: some View {
        if let photoData = dog.photoData, let image = Image(data: photoData) {
            image
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "pawprint.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }
}
