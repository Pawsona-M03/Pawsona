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
                    TextField("Adoption fee in IDR", text: $viewModel.priceText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Adoption fee in Indonesian rupiah")
                } else {
                    LabeledContent("Adoption fee", value: "Free")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Adoption fee")
                        .accessibilityValue("Free")
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
                    "I consent to sharing my contact details with signed-in interested adopters",
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
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canPublish || viewModel.isSaving)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("List in the Adoption Hub")
    }
}
