import SwiftUI

/// Deliberately mirrors `DogCardView`'s metrics — same fixed width, same 0.75
/// photo ratio, same centred text block — so a puppy reads as the same object
/// whether it is seen in the Puppy tab or the Adoption Hub. Price and region are
/// the only additions; they make the card taller than its Puppy tab twin, which
/// is the cost of a listing carrying what it costs and where it is.
struct MarketplaceListingCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let listing: MarketplaceListing
    var isOwnListing = false

    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 211

    private var photoHeight: CGFloat { cardHeight * 0.75 }

    var body: some View {
        VStack(spacing: 8) {
            MarketplaceListingPhotoView(
                listing: listing,
                placeholderIconHeight: photoHeight * 0.8
            )
            .frame(width: fixedWidth)
            .frame(maxWidth: flexibleWidth)
            .frame(height: photoHeight)
            .clipped()
            .overlay(alignment: .topLeading) {
                if isOwnListing {
                    Text("Your listing")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: .rect(cornerRadius: 8))
                        .padding(8)
                }
            }

            // No adoption glyph here on purpose: a heart read as "favourite" to
            // testers. `priceText` already prints "Free adoption".
            VStack(alignment: .center, spacing: 4) {
                Text(listing.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(listing.breed.isEmpty ? "Breed not set" : listing.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(listing.priceText)
                    .font(.headline)
                    .foregroundStyle(Color(.primaryBrown))
                    .lineLimit(1)
                    // The card is a fixed 162pt like its Puppy tab twin, and a
                    // long rupiah amount is the one line that will not fit.
                    // Shrinking beats truncating the number people came for.
                    .minimumScaleFactor(0.7)

                Label(listing.region, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: fixedWidth)
        .frame(maxWidth: flexibleWidth)
        .cardBackground()
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    /// At accessibility sizes the card stops being a fixed 162pt tile and grows
    /// with its column instead, exactly as `DogCardView` does.
    private var fixedWidth: CGFloat? {
        dynamicTypeSize.isAccessibilitySize ? nil : 162
    }

    private var flexibleWidth: CGFloat? {
        dynamicTypeSize.isAccessibilitySize ? .infinity : nil
    }

    private var accessibilityLabel: String {
        """
        \(isOwnListing ? "Your listing. " : "")\
        \(listing.name), \(listing.breed), \(listing.priceText), \
        \(listing.region), \(listing.status.displayName)
        """
    }
}
