import SwiftUI
import UIKit

/// A fixed, poster-style layout rendered to a PNG by
/// `MarketplaceShareCardRenderer` so a shared listing arrives as a picture
/// instead of a line of text.
///
/// Point sizes are hard-coded here on purpose, as in `DogPDFReportView`: the
/// output is a raster at a fixed canvas size, so it cannot reflow for Dynamic
/// Type, and letting text styles scale it would only break the layout. The
/// on-screen listing UI remains fully Dynamic Type driven.
struct MarketplaceShareCardView: View {
    static let width: CGFloat = 900

    let listing: MarketplaceListing
    let sellerProfile: SellerProfile?

    var body: some View {
        VStack(spacing: 0) {
            hero

            VStack(alignment: .leading, spacing: 28) {
                price
                facts
                vaccination
                contact
            }
            .padding(44)
            .frame(maxWidth: .infinity, alignment: .leading)

            footer
        }
        .frame(width: Self.width)
        .background(.white)
    }

    private var hero: some View {
        photo
            .frame(width: Self.width, height: 620)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.name)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(listing.breed.isEmpty ? "Breed not set" : listing.breed)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(44)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
    }

    @ViewBuilder
    private var photo: some View {
        if let photoData = listing.photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            listing.backgroundColor.pastelColor
                .overlay(alignment: .bottom) {
                    Image(.dogPlaceholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 380)
                }
        }
    }

    private var price: some View {
        Text(listing.priceText)
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(Color(.primaryBrown))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceShareCardFactRow(
                icon: "mappin.and.ellipse",
                text: listing.region.isEmpty ? "Location not set" : listing.region
            )
            MarketplaceShareCardFactRow(icon: "birthday.cake", text: listing.ageText)

            if let sex = listing.sex {
                MarketplaceShareCardFactRow(
                    icon: "pawprint",
                    text: sex == .male ? "Male" : "Female"
                )
            }
        }
    }

    private var vaccination: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vaccination")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.gray)

            Text(listing.vaccinationSummary.displayText)
                .font(.system(size: 30))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.primaryBrown).opacity(0.08))
        .clipShape(.rect(cornerRadius: 20))
    }

    /// Names the lister and points the reader back into the app. The lister's
    /// phone number is deliberately absent: in-app it sits behind an explicit
    /// "Contact Lister" tap by a signed-in user, and a shared image travels
    /// further than the person who shared it can see.
    private var contact: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact lister")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.gray)

            Text(sellerProfile?.displayName ?? "Pawsona lister")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(contactDetailText)
                .font(.system(size: 26))
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.primaryBrown).opacity(0.3), lineWidth: 2)
        }
    }

    private var contactDetailText: String {
        guard let sellerProfile else {
            return "Open the Pawsona Adoption Hub to contact this lister."
        }
        return """
        \(sellerProfile.sellerType.displayName) · \(sellerProfile.region)
        Message them in the Pawsona Adoption Hub.
        """
    }

    private var footer: some View {
        HStack(spacing: 16) {
            // An SF Symbol rather than the app icon: `AppIcon` is an
            // appiconset, and iOS does not vend those through `Image(named:)`,
            // so drawing it here would leave a blank square in every share.
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(.primaryBrown))

            Text("Pawsona Adoption Hub")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color(.primaryBrown))

            Spacer()

            Text(listing.listingType == .adoption ? "Looking for a home" : "For sale")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(Color(.primaryBrown).opacity(0.08))
    }
}

#Preview {
    MarketplaceShareCardView(
        listing: MarketplaceListing(
            id: "preview",
            sourceDogID: "preview-dog",
            sellerProfileID: "preview-seller",
            sellerCreatorRecordName: nil,
            name: "Berry",
            breed: "Labrador Retriever",
            dateOfBirth: Date(timeIntervalSinceNow: -60 * 60 * 24 * 120),
            sex: .female,
            weight: 8.4,
            backgroundColor: .green,
            photoData: nil,
            vaccinationSummary: MarketplaceVaccinationSummary(
                vaccineNames: ["Rabies", "DHPP"],
                recordCount: 3
            ),
            listingType: .sale,
            priceAmount: 4_500_000,
            currencyCode: "IDR",
            region: "Bali",
            status: .available,
            createdAt: .now,
            updatedAt: .now
        ),
        sellerProfile: SellerProfile(
            id: "preview-seller",
            creatorRecordName: nil,
            displayName: "Nathan's Kennel",
            region: "Bali",
            sellerType: .individual,
            joinedAt: .now,
            profileComplete: true,
            rulesAcceptedAt: .now
        )
    )
    .scaleEffect(0.4)
}
