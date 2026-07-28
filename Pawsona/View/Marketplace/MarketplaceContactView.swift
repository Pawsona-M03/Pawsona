import SwiftUI

struct MarketplaceContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let contact: SellerContact
    let puppyName: String

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Open WhatsApp", systemImage: "message") {
                        openWhatsApp()
                    }

                    Button("Call Lister", systemImage: "phone") {
                        openPhone()
                    }
                } header: {
                    Text("Contact lister")
                } footer: {
                    Text(
                        "You are leaving Pawsona to contact the lister. Pawsona does not process payments or messages."
                    )
                }
            }
            .navigationTitle(puppyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openWhatsApp() {
        guard let url = try? WhatsAppURLBuilder.url(
            number: contact.whatsAppNumber,
            puppyName: puppyName
        ) else {
            return
        }
        openURL(url)
    }

    private func openPhone() {
        guard let url = try? WhatsAppURLBuilder.phoneURL(number: contact.whatsAppNumber) else {
            return
        }
        openURL(url)
    }
}
