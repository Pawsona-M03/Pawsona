import SwiftUI

/// One icon-and-text line inside `MarketplaceShareCardView`. Sized in fixed
/// points because it renders into a raster, not onto a screen.
struct MarketplaceShareCardFactRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Color(.primaryBrown))
                .frame(width: 36)

            Text(text)
                .font(.system(size: 30))
                .foregroundStyle(.black)
                .lineLimit(1)
        }
    }
}
