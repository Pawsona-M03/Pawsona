import SwiftUI
import UIKit

struct MarketplaceListingPhotoView: View {
    let listing: MarketplaceListing
    var placeholderIconHeight: CGFloat = 128

    var body: some View {
        if let photoData = listing.photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(listing.backgroundColor.color)
                .overlay(alignment: .bottom) {
                    Image(.dogPlaceholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: placeholderIconHeight)
                }
        }
    }
}
