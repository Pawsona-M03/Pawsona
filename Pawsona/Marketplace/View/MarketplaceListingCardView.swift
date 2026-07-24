import SwiftUI

struct MarketplaceListingCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let listing: MarketplaceListing

    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MarketplaceListingPhotoView(
                listing: listing,
                placeholderIconHeight: cardHeight * 0.42
            )
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight * 0.58)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(listing.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if listing.listingType == .adoption {
                        Image(systemName: "heart")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }

                Text(listing.breed.isEmpty ? "Breed not set" : listing.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(listing.priceText)
                    .font(.headline)
                    .foregroundStyle(Color(.primaryBrown))
                    .lineLimit(1)

                Label(listing.region, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .cardBackground()
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        """
        \(listing.name), \(listing.breed), \(listing.priceText), \
        \(listing.region), \(listing.status.displayName)
        """
    }
}
