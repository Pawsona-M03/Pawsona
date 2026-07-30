import SwiftUI
import UIKit

/// Rasterises `MarketplaceShareCardView` so a listing can be shared as a
/// picture. Rendering is main-actor work (it walks a SwiftUI view tree) and
/// costs real time on a listing with a full-resolution photo, so callers should
/// do it once per listing rather than on every appearance.
enum MarketplaceShareCardRenderer {
    static func image(
        for listing: MarketplaceListing,
        sellerProfile: SellerProfile?
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: MarketplaceShareCardView(
                listing: listing,
                sellerProfile: sellerProfile
            )
            // The card is a fixed poster on a white background, so every colour
            // inside it has to resolve light. Without this a seller sharing from
            // Dark Mode exports a dark hero and dark text onto white.
            .environment(\.colorScheme, .light)
        )
        renderer.proposedSize = ProposedViewSize(
            width: MarketplaceShareCardView.width,
            height: nil
        )
        // 2x keeps text crisp when the card is opened full-screen in Photos or
        // a messaging app, without pushing the PNG to a size that chokes a share
        // sheet on a slow connection.
        renderer.scale = 2
        return renderer.uiImage
    }
}
