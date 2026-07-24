//
//  VaccineRecordRowView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

struct VaccineRecordRowView: View {
    let vaccineRecord: VaccineRecord
    var showsDogName: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "syringe")
                .font(.title3)
                .foregroundStyle(Color(.vaccine))
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vaccineRecord.vaccineNames)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if showsDogName {
                    if isUnassigned {
                        Label("No dog assigned", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(vaccineRecord.dogList ?? [], id: \.id) { dog in
                                VaccineRecordDogBadge(dog: dog)
                            }
                        }
                    }
                }

                if let notes = vaccineRecord.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dateText: String {
        let date = vaccineRecord.dateGiven.formatted(.dateTime.day().month(.abbreviated).year())
        let time = vaccineRecord.dateGiven.formatted(.dateTime.hour().minute())
        return "\(date) - \(time)"
    }

    private var isUnassigned: Bool {
        vaccineRecord.dogList?.isEmpty ?? true
    }

    private var accessibilityLabel: String {
        guard showsDogName else {
            return "\(vaccineRecord.vaccineNames), given \(dateText)"
        }

        if isUnassigned {
            return "\(vaccineRecord.vaccineNames), given \(dateText). No dog assigned"
        }

        return "\(vaccineRecord.vaccineNames) for \(vaccineRecord.dogNames), given \(dateText)"
    }
}

private struct VaccineRecordDogBadge: View {
    let dog: Dog

    @ScaledMetric private var avatarSize = 48
    @ScaledMetric private var labelWidth = 52

    var body: some View {
        VStack(spacing: 4) {
            DogPhotoView(dog: dog, placeholderIconHeight: avatarSize / 2)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(.circle)

            Text(dog.displayName)
                .font(.caption2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: labelWidth)
        }
    }
}

#Preview {
    VaccineRecordRowView(
        vaccineRecord: VaccineRecord(
            vaccines: [.rabies, .bordetella],
            dateGiven: .now,
            notes: "Booster due next year"
        ),
        showsDogName: true
    )
    .padding()
}
