//
//  DogPhotoView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI
import UIKit

struct DogPhotoView: View {
    let dog: Dog
    var placeholderIconHeight: CGFloat = 128

    var body: some View {
        if let uiImage = DogPhotoCache.image(for: dog) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(dog.backgroundColor.color.opacity(0.2))
                .overlay(alignment: .bottom) {
                    Image(.dogPlaceholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: placeholderIconHeight)
                }
        }
    }
}

#Preview {
    DogPhotoView(dog: Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green))
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: 16))
        .padding()
}
