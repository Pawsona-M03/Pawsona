import SwiftUI

struct MarketplaceSellerProfileCard: View {
    let profile: SellerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName)
                        .font(.headline)
                    Text("\(profile.sellerType.displayName) · \(profile.region)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if profile.profileComplete {
                    Label("Complete Lister Profile", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if profile.profileComplete {
                Text(profile.completenessExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(profile.completenessExplanation)
            }

            Text("Joined \(profile.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardBackground()
        .accessibilityElement(children: .combine)
    }
}
