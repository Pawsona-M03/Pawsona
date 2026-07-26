import SwiftUI

struct BlockedSellersView: View {
    @State private var viewModel: BlockedSellersViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        repository: any MarketplaceRepository,
        blockStore: any SellerBlocking
    ) {
        _viewModel = State(
            initialValue: BlockedSellersViewModel(
                repository: repository,
                blockStore: blockStore
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading, viewModel.isEmpty {
                    ProgressView("Loading blocked sellers")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Loading blocked sellers")
                } else if viewModel.isEmpty {
                    ContentUnavailableView {
                        Label("No Blocked Sellers", systemImage: "person.crop.circle.badge.checkmark")
                    } description: {
                        Text(
                            """
                            Sellers you block are hidden from Marketplace on \
                            this device. They'll appear here so you can \
                            unblock them.
                            """
                        )
                    }
                } else {
                    List {
                        Section {
                            ForEach(viewModel.sellers) { seller in
                                BlockedSellerRow(seller: seller) {
                                    viewModel.unblock(seller)
                                }
                            }
                        } footer: {
                            Text("Blocking is saved on this device only.")
                        }
                    }
                }
            }
            .navigationTitle("Blocked Sellers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
    }
}
