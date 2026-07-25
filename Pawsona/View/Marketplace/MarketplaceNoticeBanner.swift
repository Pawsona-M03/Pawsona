import SwiftUI

/// A non-blocking failure notice for a screen that still has usable content.
/// Reserved for the cases where something secondary broke — a continuation
/// page, a "load more" — and the listings already on screen remain valid.
struct MarketplaceNoticeBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Dismiss", systemImage: "xmark", action: dismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }
}
