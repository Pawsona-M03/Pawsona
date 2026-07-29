import SwiftUI

/// The scrolling card that rides over a listing's hero photo.
///
/// Mirrors the Puppy tab's detail sheet — same corner radius, same centred
/// header, same `DogStatBox` row — so a listing and a private puppy profile
/// read as two views of one animal rather than two unrelated screens.
struct MarketplaceListingSheetView: View {
    let viewModel: MarketplaceDetailViewModel
    let canUpdateFromPuppy: Bool
    let shareCardImage: Image?
    let shareText: String
    let cornerRadius: CGFloat
    let editTerms: () -> Void
    let updateFromPuppy: () -> Void
    let remove: () -> Void
    let contactLister: () -> Void
    let report: () -> Void
    let toggleBlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.listing.name)
                        .font(.title2.bold())
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityHeading(.h1)

                    Spacer()

                    MarketplaceStatusBadge(status: viewModel.listing.status)
                }

                Text(viewModel.listing.breed.isEmpty ? "Breed not set" : viewModel.listing.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Text(viewModel.listing.priceText)
                    .font(.title3.bold())
                    .foregroundStyle(Color(.primaryBrown))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(
                        viewModel.listing.listingType == .adoption
                            ? "Free adoption" : "Adoption fee \(viewModel.listing.priceText)"
                    )

                Label(viewModel.listing.region, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 24)
            .padding(.horizontal)

            MarketplaceListingFactsView(listing: viewModel.listing)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Vaccination summary")
                    .font(.headline)
                Text(viewModel.listing.vaccinationSummary.displayText)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
            .padding(.horizontal)

            if let sellerProfile = viewModel.sellerProfile {
                MarketplaceSellerProfileCard(profile: sellerProfile)
                    .padding(.horizontal)
            } else if viewModel.isLoading {
                ProgressView("Loading lister profile")
            }

            if viewModel.isOwner {
                MarketplaceOwnerActionsView(
                    listing: viewModel.listing,
                    canUpdateFromPuppy: canUpdateFromPuppy,
                    isPerformingAction: viewModel.isPerformingAction,
                    editTerms: editTerms,
                    updateFromPuppy: updateFromPuppy,
                    updateStatus: { status in
                        Task { await viewModel.updateStatus(status) }
                    },
                    remove: remove
                )
                .padding(.horizontal)
            } else {
                Button("Contact Lister", systemImage: "message", action: contactLister)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isPerformingAction || viewModel.isSellerBlocked)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }

            MarketplaceListingActionsRow(
                listingName: viewModel.listing.name,
                shareText: shareText,
                shareCardImage: shareCardImage,
                canReportOrBlock: viewModel.canReportOrBlock,
                isSellerBlocked: viewModel.isSellerBlocked,
                report: report,
                toggleBlock: toggleBlock
            )
            .padding(.horizontal)
        }
        // Clears the floating tab bar so the last control stays tappable.
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(.appBackground))
        .clipShape(.rect(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius))
    }
}
