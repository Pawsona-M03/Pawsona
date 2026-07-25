import SwiftUI

/// The share / report / block row beneath a listing's details.
///
/// Report and Block are absent on your own listing rather than disabled: they
/// are not actions an owner can meaningfully take against themselves, and a
/// self-block used to hide the user's own puppy from Marketplace.
struct MarketplaceListingActionsRow: View {
    let listingName: String
    let shareText: String
    /// Absent until the card finishes rasterising, and on any listing whose
    /// card could not be rendered — the row falls back to sharing text.
    var shareCardImage: Image?
    let canReportOrBlock: Bool
    let isSellerBlocked: Bool
    let report: () -> Void
    let toggleBlock: () -> Void

    var body: some View {
        HStack {
            shareLink

            Spacer()

            if canReportOrBlock {
                Button("Report", systemImage: "exclamationmark.bubble", action: report)

                Button(
                    isSellerBlocked ? "Unblock Seller" : "Block Seller",
                    systemImage: isSellerBlocked
                        ? "person.crop.circle.badge.checkmark"
                        : "person.crop.circle.badge.xmark",
                    action: toggleBlock
                )
            }
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var shareLink: some View {
        if let shareCardImage {
            ShareLink(
                item: shareCardImage,
                subject: Text("\(listingName) on Pawsona"),
                message: Text(shareText),
                preview: SharePreview("\(listingName) on Pawsona", image: shareCardImage)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } else {
            // The card is still rasterising. Sharing the details as text beats
            // a dead button in the meantime.
            ShareLink(
                item: shareText,
                subject: Text("\(listingName) on Pawsona"),
                message: Text("View this Pawsona marketplace listing.")
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
