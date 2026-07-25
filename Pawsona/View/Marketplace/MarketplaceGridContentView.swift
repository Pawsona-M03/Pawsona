import SwiftUI

struct MarketplaceGridContentView: View {
    let listings: [MarketplaceListing]
    let columns: [GridItem]
    let isLoadingNextPage: Bool
    let hasNextPage: Bool
    var noticeMessage: String?
    var dismissNotice: () -> Void = {}
    let loadNextPage: () -> Void

    var body: some View {
        ScrollView {
            if let noticeMessage {
                MarketplaceNoticeBanner(message: noticeMessage, dismiss: dismissNotice)
                    .padding(.bottom, 8)
            }

            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(listings) { listing in
                    NavigationLink(value: listing) {
                        MarketplaceListingCardView(listing: listing)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows marketplace listing details")
                }
            }
            .padding(.horizontal)

            if hasNextPage {
                Button("Load More", action: loadNextPage)
                    .buttonStyle(.bordered)
                    .disabled(isLoadingNextPage)
                    .padding()
                    .overlay {
                        if isLoadingNextPage {
                            ProgressView()
                                .accessibilityLabel("Loading more listings")
                        }
                    }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityRotor("Marketplace listings") {
            ForEach(listings) { listing in
                AccessibilityRotorEntry(listing.name, id: listing.id)
            }
        }
    }
}
