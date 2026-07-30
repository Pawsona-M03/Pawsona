import SwiftUI

struct MarketplacePublishingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MarketplacePublishingViewModel

    let puppy: MarketplacePuppySnapshot

    init(
        puppy: MarketplacePuppySnapshot,
        repository: any MarketplaceRepository
    ) {
        self.puppy = puppy
        _viewModel = State(
            initialValue: MarketplacePublishingViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .checkingAccount:
                    ProgressView("Checking iCloud account")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Checking iCloud account")
                case let .requiresICloud(message):
                    ContentUnavailableView {
                        Label("iCloud Required", systemImage: "icloud.slash")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Done") {
                            dismiss()
                        }
                    }
                case .sellerProfile:
                    SellerProfileFormView(viewModel: viewModel)
                case .confirmation:
                    MarketplacePublishConfirmationView(
                        viewModel: viewModel,
                        puppy: puppy
                    )
                case let .published(listing):
                    ContentUnavailableView {
                        Label("Listing Published", systemImage: "checkmark.circle")
                    } description: {
                        Text("\(listing.name) is now visible in the Adoption Hub.")
                    } actions: {
                        Button("Done") {
                            AccessibilityNotification.Announcement("Adoption listing published").post()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .background(Color(.appBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .task {
                if case .checkingAccount = viewModel.step {
                    await viewModel.prepare()
                }
            }
            .alert("Adoption Hub", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
