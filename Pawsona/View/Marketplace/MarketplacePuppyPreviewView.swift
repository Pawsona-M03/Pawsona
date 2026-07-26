import SwiftUI
import UIKit

struct MarketplacePuppyPreviewView: View {
    let puppy: MarketplacePuppySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let photoData = puppy.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .accessibilityLabel("Photo of \(puppy.name)")
            } else {
                Rectangle()
                    .fill(puppy.backgroundColor.color.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .overlay {
                        Image(.dogPlaceholder)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                    .accessibilityLabel("No photo for \(puppy.name)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(puppy.name)
                    .font(.title2.bold())
                Text(puppy.breed.isEmpty ? "Breed not set" : puppy.breed)
                    .foregroundStyle(.secondary)
                Text(PuppyAgeText.value(from: puppy.dateOfBirth) ?? "Age not provided")
                    .foregroundStyle(.secondary)
                Text(puppy.vaccinationSummary.displayText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .bottom])
        }
        .cardBackground()
        .clipShape(.rect(cornerRadius: 12))
    }
}
