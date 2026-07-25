import SwiftUI

struct MarketplaceListingTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MarketplaceListingTermsViewModel

    private let listingName: String
    private let onSave: (MarketplaceListing) -> Void

    init(
        listing: MarketplaceListing,
        repository: any MarketplaceRepository,
        onSave: @escaping (MarketplaceListing) -> Void
    ) {
        self.listingName = listing.name
        self.onSave = onSave
        _viewModel = State(
            initialValue: MarketplaceListingTermsViewModel(
                listing: listing,
                repository: repository
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Listing type", selection: $viewModel.listingType) {
                        ForEach(MarketplaceListingType.allCases) { listingType in
                            Text(listingType.displayName).tag(listingType)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.listingType == .sale {
                        TextField("Price in IDR", text: $viewModel.priceText)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Sale price in Indonesian rupiah")

                        if let formattedPricePreview = viewModel.formattedPricePreview {
                            LabeledContent("Buyers see", value: formattedPricePreview)
                        }
                    } else {
                        LabeledContent("Price", value: "Free adoption")
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Price")
                            .accessibilityValue("Free adoption")
                    }
                } header: {
                    Text("Listing terms")
                } footer: {
                    Text(
                        "Changes go live immediately. Switching to adoption removes the price."
                    )
                }
            }
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ProgressView("Saving")
                        .accessibilityLabel("Saving listing changes")
                }
            }
            .alert("Marketplace", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func save() {
        Task {
            guard let updated = await viewModel.save() else { return }
            onSave(updated)
            AccessibilityNotification.Announcement("\(listingName) listing updated").post()
            dismiss()
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
