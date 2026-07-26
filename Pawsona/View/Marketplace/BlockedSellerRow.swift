import SwiftUI

struct BlockedSellerRow: View {
    let seller: BlockedSeller
    let unblock: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(seller.displayName)
                    .font(.headline)
                if let region = seller.region, !region.isEmpty {
                    Text(region)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Unblock", action: unblock)
                .buttonStyle(.bordered)
                .accessibilityLabel("Unblock \(seller.displayName)")
        }
    }
}
