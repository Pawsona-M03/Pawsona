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
                    ProgressView("Loading blocked listers")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Loading blocked listers")
                } else if viewModel.isEmpty {
                    ContentUnavailableView {
                        Label("No Blocked Listers", systemImage: "person.crop.circle.badge.checkmark")
                    } description: {
                        Text(
                            """
                            Listers you block are hidden from Marketplace on \
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
            .navigationTitle("Blocked Listers")
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
