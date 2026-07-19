//
//  VaccineRecordRowView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

struct VaccineRecordRowView: View {
    let vaccineRecord: VaccineRecord

    var body: some View {
        VStack(alignment: .leading) {
            Text(vaccineRecord.vaccine.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(vaccineRecord.dateGiven.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let notes = vaccineRecord.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let dateGiven = vaccineRecord.dateGiven.formatted(date: .abbreviated, time: .omitted)
        return "\(vaccineRecord.vaccine.displayName), given \(dateGiven)"
    }
}

#Preview {
    VaccineRecordRowView(
        vaccineRecord: VaccineRecord(
            vaccine: .rabies,
            dateGiven: .now,
            notes: "Booster due next year"
        )
    )
    .padding()
}
