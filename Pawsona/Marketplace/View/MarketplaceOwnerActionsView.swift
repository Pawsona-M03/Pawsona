import SwiftUI

struct MarketplaceOwnerActionsView: View {
    let listing: MarketplaceListing
    let canUpdateFromPuppy: Bool
    let isPerformingAction: Bool
    let updateFromPuppy: () -> Void
    let updateStatus: (MarketplaceListingStatus) -> Void
    let remove: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(
                "Update listing from puppy profile",
                systemImage: "arrow.triangle.2.circlepath",
                action: updateFromPuppy
            )
            .buttonStyle(.borderedProminent)
            .disabled(isPerformingAction)

            Menu("Change Listing Status", systemImage: "slider.horizontal.3") {
                Button("Mark Available", systemImage: "checkmark.circle") {
                    updateStatus(.available)
                }
                Button("Pause Listing", systemImage: "pause.circle") {
                    updateStatus(.paused)
                }
                Button("Mark Reserved", systemImage: "clock") {
                    updateStatus(.reserved)
                }
                Button("Mark Sold", systemImage: "checkmark.seal") {
                    updateStatus(.sold)
                }
            }
            .buttonStyle(.bordered)
            .disabled(isPerformingAction)

            Button("Remove Listing", systemImage: "trash", role: .destructive, action: remove)
                .buttonStyle(.bordered)
                .disabled(isPerformingAction)

            if !canUpdateFromPuppy {
                Text("Open this puppy in the Puppy tab to refresh its public listing snapshot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
