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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MarketplaceListingPhotoView(
                    listing: viewModel.listing,
                    placeholderIconHeight: 220
                )
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .background(viewModel.listing.backgroundColor.pastelColor)
                .clipped()
                .accessibilityLabel("Photo of \(viewModel.listing.name)")

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(viewModel.listing.name)
                                .font(.title.bold())
                                .accessibilityHeading(.h1)

                            Spacer()

                            MarketplaceStatusBadge(status: viewModel.listing.status)
                        }

                        Text(viewModel.listing.breed.isEmpty ? "Breed not set" : viewModel.listing.breed)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(viewModel.listing.priceText)
                            .font(.title2.bold())
                            .foregroundStyle(Color(.primaryBrown))
                            .accessibilityLabel(
                                viewModel.listing.listingType == .adoption
                                    ? "Free adoption" : "Price \(viewModel.listing.priceText)"
                            )

                        Label(viewModel.listing.region, systemImage: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                    }

                    MarketplaceListingFactsView(listing: viewModel.listing)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vaccination summary")
                            .font(.headline)
                        Text(viewModel.listing.vaccinationSummary.displayText)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardBackground()

                    if let sellerProfile = viewModel.sellerProfile {
                        MarketplaceSellerProfileCard(profile: sellerProfile)
                    } else if viewModel.isLoading {
                        ProgressView("Loading lister profile")
                    }

                    if viewModel.isOwner {
                        MarketplaceOwnerActionsView(
                            listing: viewModel.listing,
                            canUpdateFromPuppy: updateListingFromPuppy != nil,
                            isPerformingAction: viewModel.isPerformingAction,
                            editTerms: { isShowingTermsEditor = true },
                            updateFromPuppy: updateFromPuppy,
                            updateStatus: { status in
                                Task { await viewModel.updateStatus(status) }
                            },
                            remove: {
                                isConfirmingRemoval = true
                            }
                        )
                    } else {
                        Button("Contact Lister", systemImage: "message") {
                            Task {
                                await viewModel.revealContact()
                                isShowingContact = viewModel.sellerContact != nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isPerformingAction || viewModel.isSellerBlocked)
                        .frame(maxWidth: .infinity)
                    }

                    MarketplaceListingActionsRow(
                        listingName: viewModel.listing.name,
                        shareText: shareText,
                        shareCardImage: shareCardImage,
                        canReportOrBlock: viewModel.canReportOrBlock,
                        isSellerBlocked: viewModel.isSellerBlocked,
                        report: { isShowingReport = true },
                        toggleBlock: { isConfirmingBlock = true }
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.appBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
        .confirmationDialog(
            viewModel.isSellerBlocked ? "Unblock this lister?" : "Block this lister?",
            isPresented: $isConfirmingBlock,
            titleVisibility: .visible
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
