import SwiftUI

struct MarketplacePublishConfirmationView: View {
    @Bindable var viewModel: MarketplacePublishingViewModel
    let puppy: MarketplacePuppySnapshot

    var body: some View {
        Form {
            Section {
                MarketplacePuppyPreviewView(puppy: puppy)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text("Puppy preview")
            } footer: {
                Text("This is a snapshot. Later puppy edits stay private until you explicitly update the listing.")
            }

            Section("Listing") {
                Picker("Listing type", selection: $viewModel.listingType) {
                    ForEach(MarketplaceListingType.allCases) { listingType in
                        Text(listingType.displayName).tag(listingType)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.listingType == .sale {
                    TextField("Price in IDR", text: $viewModel.priceText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Sale price in Indonesian rupiah")
                } else {
                    LabeledContent("Price", value: "Free adoption")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Price")
                        .accessibilityValue("Free adoption")
                }

                if let sellerProfile = viewModel.sellerProfile {
                    LabeledContent("Region", value: sellerProfile.region)
                }
            }

            Section("Before publishing") {
                Toggle(
                    "I understand these puppy details and the vaccination summary will be public",
                    isOn: $viewModel.acceptedPublicSharing
                )
                Toggle(
                    "I consent to sharing my contact details with signed-in interested buyers",
                    isOn: $viewModel.acceptedContactSharing
                )

                Text(
                    "Pawsona will not publish reminders, private notes, full vaccination documents, scan source images, or an exact address."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section {
                Button("Publish Listing", systemImage: "square.and.arrow.up") {
                    Task { await viewModel.publish(puppy: puppy) }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("ActionBrown"))
                .foregroundStyle(.white)
                .disabled(!viewModel.canPublish || viewModel.isSaving)
            }
        }
        .navigationTitle("List on Marketplace")
    }
}
