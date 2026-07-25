import SwiftUI

struct MarketplaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MarketplaceDetailViewModel
    @State private var isShowingReport = false
    @State private var isShowingContact = false
    @State private var isConfirmingBlock = false
    @State private var isConfirmingRemoval = false

    private let updateListingFromPuppy: (() async throws -> MarketplaceListing)?

    init(
        listing: MarketplaceListing,
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking,
        isKnownOwnListing: Bool = false,
        updateListingFromPuppy: (() async throws -> MarketplaceListing)? = nil
    ) {
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
                .background(viewModel.listing.backgroundColor.color.opacity(0.2))
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
                        ProgressView("Loading seller profile")
                    }

                    if viewModel.isOwner {
                        MarketplaceOwnerActionsView(
                            listing: viewModel.listing,
                            canUpdateFromPuppy: updateListingFromPuppy != nil,
                            isPerformingAction: viewModel.isPerformingAction,
                            updateFromPuppy: updateFromPuppy,
                            updateStatus: { status in
                                Task { await viewModel.updateStatus(status) }
                            },
                            remove: {
                                isConfirmingRemoval = true
                            }
                        )
                    } else {
                        Button("Contact Seller", systemImage: "message") {
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
        .sheet(isPresented: $isShowingContact) {
            if let contact = viewModel.sellerContact {
                MarketplaceContactView(contact: contact, puppyName: viewModel.listing.name)
            }
        }
        .sheet(isPresented: $isShowingReport) {
            MarketplaceReportView(listingName: viewModel.listing.name) { reason, details in
                await viewModel.submitReport(reason: reason, details: details)
            }
        }
        .confirmationDialog(
            viewModel.isSellerBlocked ? "Unblock this seller?" : "Block this seller?",
            isPresented: $isConfirmingBlock,
            titleVisibility: .visible
        ) {
            if viewModel.isSellerBlocked {
                Button("Unblock Seller") {
                    viewModel.unblockSeller()
                }
            } else {
                Button("Block Seller", role: .destructive) {
                    viewModel.blockSeller()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blocked sellers are hidden from Marketplace on this device.")
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
        .alert("Marketplace", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Marketplace", isPresented: confirmationBinding) {
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
