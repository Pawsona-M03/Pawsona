//
//  DogShareCardRenderer.swift
//  Pawsona
//

import SwiftUI
import UIKit

/// Rasterises `DogShareCardView` so a puppy's profile can be shared as a
/// picture. Rendering is main-actor work — it walks a SwiftUI view tree with a
/// full-resolution photo in it — so callers should do it once, when the user
/// actually taps share.
enum DogShareCardRenderer {
    static func pngData(for dog: Dog, colorScheme: ColorScheme) -> Data? {
        let renderer = ImageRenderer(
            content: DogShareCardView(dog: dog)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.proposedSize = ProposedViewSize(width: DogShareCardView.width, height: nil)
        // The canvas is already 1500pt wide, so 2x is only about keeping the
        // text crisp when the card is opened full-screen in Photos.
        renderer.scale = 2
        // Not `uiImage`: the card's rounded corners need the alpha channel, and
        // JPEG would flatten them onto black.
        return renderer.uiImage?.pngData()
    }
}
