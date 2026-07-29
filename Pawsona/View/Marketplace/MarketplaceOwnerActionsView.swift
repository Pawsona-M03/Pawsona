import SwiftUI

struct MarketplaceOwnerActionsView: View {
    let listing: MarketplaceListing
    let canUpdateFromPuppy: Bool
    let isPerformingAction: Bool
    let editTerms: () -> Void
    let updateFromPuppy: () -> Void
    let updateStatus: (MarketplaceListingStatus) -> Void
    let remove: () -> Void

    var body: some View {
        // Every control stretches to the full content width so the stack reads
        // as one aligned column. Sized-to-fit buttons inside the detail view's
        // leading-aligned VStack looked ragged and off-centre.
        VStack(spacing: 12) {
            Button("Edit Fee & Listing Type", systemImage: "tag", action: editTerms)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isPerformingAction)

            Button(
                "Update listing from puppy profile",
                systemImage: "arrow.triangle.2.circlepath",
                action: updateFromPuppy
            )
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
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
                Button("Mark Adopted", systemImage: "checkmark.seal") {
                    updateStatus(.sold)
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(isPerformingAction)

            Button("Remove Listing", systemImage: "trash", role: .destructive, action: remove)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isPerformingAction)

            if !canUpdateFromPuppy {
                Text("Open this puppy in the Puppy tab to refresh its public listing snapshot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
