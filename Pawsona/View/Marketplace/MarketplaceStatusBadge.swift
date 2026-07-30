import SwiftUI

struct MarketplaceStatusBadge: View {
    let status: MarketplaceListingStatus

    var body: some View {
        Label(status.displayName, systemImage: iconName)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tint.opacity(0.15), in: .capsule)
            .accessibilityLabel("Listing status")
            .accessibilityValue(status.displayName)
    }

    /// Only `available` is coloured — it is the one status a reader scans for.
    /// The rest stay neutral so the green keeps its meaning. `statusAvailable`
    /// carries a darker green in light mode and a brighter one in dark so the
    /// label clears contrast against its own tinted capsule either way.
    private var tint: Color {
        switch status {
        case .available: Color(.statusAvailable)
        default: .secondary
        }
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
