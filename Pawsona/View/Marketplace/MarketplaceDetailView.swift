import SwiftUI
import UIKit

struct MarketplaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MarketplaceDetailViewModel
    @State private var isShowingReport = false
    @State private var isShowingContact = false
    @State private var isConfirmingBlock = false
    @State private var isConfirmingRemoval = false
    @State private var isShowingTermsEditor = false
    @State private var shareCardImage: Image?

    private let repository: any MarketplaceRepository
    private let updateListingFromPuppy: (() async throws -> MarketplaceListing)?

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 380
    private let sheetCornerRadius: CGFloat = 32

    init(
        listing: MarketplaceListing,
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking,
        isKnownOwnListing: Bool = false,
        updateListingFromPuppy: (() async throws -> MarketplaceListing)? = nil
    ) {
        self.repository = repository
        _viewModel = State(
            initialValue: MarketplaceDetailViewModel(
                listing: listing,
                repository: repository,
                blockStore: blockStore,
                isKnownOwnListing: isKnownOwnListing
            )
        )
        self.updateListingFromPuppy = updateListingFromPuppy
    }

    var body: some View {
        ZStack(alignment: .top) {
            MarketplaceListingPhotoView(
                listing: viewModel.listing,
                placeholderIconHeight: displayedHeroHeight * 0.8
            )
            .frame(maxWidth: .infinity)
            .frame(height: displayedHeroHeight)
            .background(viewModel.listing.backgroundColor.pastelColor)
            .clipped()
            .ignoresSafeArea(edges: .top)
            .accessibilityLabel("Photo of \(viewModel.listing.name)")
            .accessibilityHidden(viewModel.listing.photoData == nil)

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: displayedHeroHeight - sheetCornerRadius)

                    MarketplaceListingSheetView(
                        viewModel: viewModel,
                        canUpdateFromPuppy: updateListingFromPuppy != nil,
                        shareCardImage: shareCardImage,
                        shareText: shareText,
                        cornerRadius: sheetCornerRadius,
                        editTerms: { isShowingTermsEditor = true },
                        updateFromPuppy: updateFromPuppy,
                        remove: { isConfirmingRemoval = true },
                        contactLister: revealContact,
                        report: { isShowingReport = true },
                        toggleBlock: { isConfirmingBlock = true }
                    )
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
        .background(Color(.appBackground).ignoresSafeArea(edges: .bottom))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // The hero behind this bar is always a light pastel in both
        // appearances, so the bar's content has to stay dark — the same reason
        // `DogDetailView` pins it.
        .toolbarColorScheme(.light, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .task(id: shareCardIdentity) {
            // Let the screen paint first — rasterising the card is main-actor
            // work and the share button is never the first thing tapped.
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            shareCardImage = MarketplaceShareCardRenderer.image(
                for: viewModel.listing,
                sellerProfile: viewModel.sellerProfile
            )
            .map(Image.init(uiImage:))
        }
        .sheet(isPresented: $isShowingContact) {
            if let contact = viewModel.sellerContact {
                MarketplaceContactView(contact: contact, puppyName: viewModel.listing.name)
            }
        }
        .sheet(isPresented: $isShowingTermsEditor) {
            MarketplaceListingTermsView(
                listing: viewModel.listing,
                repository: repository
            ) { updated in
                viewModel.replaceListing(updated, message: "Listing terms updated.")
            }
        }
        .sheet(isPresented: $isShowingReport) {
            MarketplaceReportView(listingName: viewModel.listing.name) { reason, details in
                await viewModel.submitReport(reason: reason, details: details)
            }
        }
        // An alert rather than a confirmation dialog: every other warning in
        // Pawsona is a centred modal, and the action-sheet variant anchored
        // itself to the button, half-covering the listing it asks about.
        .alert(
            viewModel.isSellerBlocked ? "Unblock this lister?" : "Block this lister?",
            isPresented: $isConfirmingBlock
        ) {
            if viewModel.isSellerBlocked {
                Button("Unblock Lister") {
                    viewModel.unblockSeller()
                }
            } else {
                Button("Block Lister", role: .destructive) {
                    viewModel.blockSeller()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blocked listers are hidden from the Adoption Hub on this device.")
        }
        .confirmationDialog(
            "Remove this public listing?",
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove Listing", role: .destructive) {
                Task {
                    if await viewModel.removeListing() {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your private puppy profile remains in Pawsona.")
        }
        .alert("Adoption Hub", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Adoption Hub", isPresented: confirmationBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.confirmationMessage ?? "")
        }
    }

    /// The hero grows with Dynamic Type but stops short of swallowing the
    /// screen, matching `DogDetailView`'s cap.
    private var displayedHeroHeight: CGFloat {
        min(heroHeight, 520)
    }

    private func revealContact() {
        Task {
            await viewModel.revealContact()
            isShowingContact = viewModel.sellerContact != nil
        }
    }

    private var shareText: String {
        """
        \(viewModel.listing.name) · \(viewModel.listing.breed) · \
        \(viewModel.listing.priceText) · \(viewModel.listing.region)
        """
    }

    /// Re-renders the card when anything it draws changes — the listing itself
    /// (a price edit, a refreshed photo) or the seller profile arriving late.
    private var shareCardIdentity: String {
        [
            viewModel.listing.id,
            viewModel.listing.updatedAt.formatted(.iso8601),
            viewModel.sellerProfile?.id ?? ""
        ]
        .joined(separator: "|")
    }

    private func updateFromPuppy() {
        guard let updateListingFromPuppy else {
            viewModel.showMessage("Open this puppy in the Puppy tab to update its public listing.")
            return
        }
        Task {
            do {
                viewModel.replaceListing(try await updateListingFromPuppy())
            } catch {
                viewModel.showMessage(
                    (error as? LocalizedError)?.errorDescription
                        ?? MarketplaceError.serviceUnavailable.localizedDescription
                )
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.confirmationMessage != nil },
            set: { if !$0 { viewModel.confirmationMessage = nil } }
        )
    }
}
