import SwiftUI

struct MarketplaceStatusBadge: View {
    let status: MarketplaceListingStatus

    var body: some View {
        Label(status.displayName, systemImage: iconName)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.12), in: .capsule)
            .accessibilityLabel("Listing status")
            .accessibilityValue(status.displayName)
    }

    private var iconName: String {
        switch status {
        case .available: "checkmark.circle"
        case .reserved: "clock"
        case .sold: "checkmark.seal"
        case .paused: "pause.circle"
        case .removed: "xmark.circle"
        }
    }
}
