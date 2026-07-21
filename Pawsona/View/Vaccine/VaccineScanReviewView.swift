//
//  VaccineScanReviewView.swift
//  Pawsona
//
//  Confirmation step between scanning a vaccine book page and writing records.
//  A page holds two or three visits, so this is where the user drops the ones
//  the camera misread before anything reaches the database.
//

import SwiftUI

struct VaccineScanReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let visits: [ScannedVisit]
    let onConfirm: ([ScannedVisit]) -> Void

    @State private var includedIDs: Set<UUID>

    init(visits: [ScannedVisit], onConfirm: @escaping ([ScannedVisit]) -> Void) {
        self.visits = visits
        self.onConfirm = onConfirm
        self._includedIDs = State(initialValue: Set(visits.map(\.id)))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(visits) { visit in
                        ScannedVisitRow(
                            visit: visit,
                            isIncluded: includedIDs.contains(visit.id),
                            action: { toggle(visit) }
                        )
                    }
                } footer: {
                    Text("Records are saved without a dog. Open each one to assign it afterwards.")
                }
            }
            .navigationTitle("Review Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(includedIDs.count)", action: confirm)
                        .disabled(includedIDs.isEmpty)
                }
            }
        }
    }

    private func toggle(_ visit: ScannedVisit) {
        if includedIDs.contains(visit.id) {
            includedIDs.remove(visit.id)
        } else {
            includedIDs.insert(visit.id)
        }
    }

    private func confirm() {
        onConfirm(visits.filter { includedIDs.contains($0.id) })
        dismiss()
    }
}

private struct ScannedVisitRow: View {
    let visit: ScannedVisit
    let isIncluded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isIncluded ? Color.brown : Color.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dateText)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(vaccineNames)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vaccineNames), \(dateText)")
        .accessibilityValue(isIncluded ? "Selected" : "Not selected")
        .accessibilityAddTraits(isIncluded ? .isSelected : [])
    }

    private var dateText: String {
        guard let dateGiven = visit.dateGiven else { return "No date found — today will be used" }
        return dateGiven.formatted(.dateTime.day().month(.abbreviated).year())
    }

    private var vaccineNames: String {
        visit.vaccines.map(\.displayName).joined(separator: ", ")
    }
}

#Preview {
    VaccineScanReviewView(
        visits: [
            ScannedVisit(
                dateGiven: Date(timeIntervalSince1970: 1_590_451_200),
                vaccines: [.parvovirus, .distemper, .parainfluenza, .hepatitis, .leptospira]
            ),
            ScannedVisit(
                dateGiven: Date(timeIntervalSince1970: 1_591_920_000),
                vaccines: [.rabies]
            )
        ]
    ) { _ in }
}
