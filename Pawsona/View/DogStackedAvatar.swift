//
//  DogStackedAvatar.swift
//  Pawsona
//

import SwiftUI
import UIKit

/// Foto bulat kecil dog buat ditampilin numpuk (overlap) dalam VaccineRecordGroupRowView.
struct DogStackedAvatar: View {
    let dog: Dog

    var body: some View {
        photo
            .frame(width: 32, height: 32)
            .clipShape(.circle)
            .overlay(Circle().stroke(.background, lineWidth: 2))
    }

    @ViewBuilder
    private var photo: some View {
        if let photoData = dog.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
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

#Preview {
    DogStackedAvatar(dog: Dog(name: "Nathan"))
}
