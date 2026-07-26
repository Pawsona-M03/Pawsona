import SwiftUI

struct MarketplaceReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reason = MarketplaceReportReason.suspectedScam
    @State private var details = ""
    @State private var isSubmitting = false

    let listingName: String
    let submit: (MarketplaceReportReason, String?) async -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Report reason", selection: $reason) {
                        ForEach(MarketplaceReportReason.allCases) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                }

                Section("Additional details") {
                    TextField(
                        "Optional context for the Pawsona team",
                        text: $details,
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                }

                Section {
                    Text(
                        "Reports are sent privately to the Pawsona team and are not shown to other marketplace users."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Text("Submitting this form contacts the Pawsona marketplace safety team.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report \(listingName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit Report") {
                        isSubmitting = true
                        Task {
                            if await submit(reason, details.isEmpty ? nil : details) {
                                dismiss()
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
}
