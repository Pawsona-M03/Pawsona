import SwiftUI

struct SellerProfileFormView: View {
    @Bindable var viewModel: MarketplacePublishingViewModel

    var body: some View {
        Form {
            Section("Lister profile") {
                TextField("Display name", text: $viewModel.displayName)
                    .textContentType(.name)

                TextField("Approximate city or region", text: $viewModel.region)
                    .textContentType(.addressCity)

                Picker("Lister type", selection: $viewModel.sellerType) {
                    ForEach(SellerType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section {
                TextField("WhatsApp number", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)

                Picker("Preferred contact method", selection: $viewModel.preferredContactMethod) {
                    ForEach(PreferredContactMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
            } header: {
                Text("Contact")
            } footer: {
                Text(
                    "Use an international number such as +62 812 3456 7890. Contact details are stored separately and require iCloud sign-in to reveal."
                )
            }

            Section("Adoption Hub rules") {
                Toggle("I accept the Pawsona Adoption Hub rules", isOn: $viewModel.acceptedMarketplaceRules)

                Text(
                    "No deposits or payments are processed by Pawsona. Never publish an exact home address, government identification, or private health documents."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Text("Adoption Hub safety support is available through Report on every listing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Complete Lister Profile") {
                    Task { await viewModel.saveSellerProfile() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canSaveProfile || viewModel.isSaving)
                .listRowBackground(Color.clear)
            } footer: {
                Text(SellerProfile.completenessExplanation)
            }
        }
        .navigationTitle("Lister Profile")
    }
}
