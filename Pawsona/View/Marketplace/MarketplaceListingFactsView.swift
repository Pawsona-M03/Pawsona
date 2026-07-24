import SwiftUI

struct MarketplaceListingFactsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let listing: MarketplaceListing

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    facts
                }
            } else {
                HStack(spacing: 12) {
                    facts
                }
            }
        }
    }

    @ViewBuilder
    private var facts: some View {
        DogStatBox(title: "Age", value: listing.ageText)
        DogStatBox(title: "Sex", value: sexText)
        DogStatBox(title: "Weight", value: weightText)
    }

    private var sexText: String {
        switch listing.sex {
        case .male: "Male"
        case .female: "Female"
        case nil: "Not set"
        }
    }

    private var weightText: String {
        guard let weight = listing.weight else { return "Not set" }
        return "\(weight.formatted(.number.precision(.fractionLength(1)))) kg"
    }
}
