//
//  DogPhotoView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI
import UIKit

struct DogPhotoView: View {
    /// Horizontal nudge applied to the placeholder artwork, as a fraction of
    /// its rendered height.
    static let placeholderOffsetRatio: CGFloat = 0.08

    let dog: Dog
    var placeholderIconHeight: CGFloat = 128

    var body: some View {
        if let uiImage = DogPhotoCache.image(for: dog) {
            // `scaledToFill` reports the *scaled* size, which is wider than the
            // container whenever the photo is more landscape than the space it
            // fills. A caller sizing this with `maxWidth: .infinity` can't
            // shrink below that, so the oversized width used to escape and drag
            // the rest of the screen out with it. Overlay content has no say in
            // its parent's size, so the photo can no longer push anything.
            Color.clear
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
        } else {
            Rectangle()
                .fill(dog.backgroundColor.pastelColor)
                .overlay(alignment: .bottom) {
                    Image(.dogPlaceholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: placeholderIconHeight)
                        // The artwork reads better nudged off centre. Scaled
                        // off the icon height so the shift stays proportional
                        // at every size this view is used at.
                        .offset(x: placeholderIconHeight * Self.placeholderOffsetRatio)
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
