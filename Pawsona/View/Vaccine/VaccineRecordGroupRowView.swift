//
//  VaccineRecordGroupRowView.swift
//  Pawsona
//

import SwiftUI

/// Satu card yang mewakili beberapa VaccineRecord dengan vaccine + tanggal yang
/// sama (hasil pilih banyak puppy sekaligus di form) — nampilin avatar dog numpuk.
struct VaccineRecordGroupRowView: View {
    let records: [VaccineRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text: nama vaccine, sama buat semua record dalam grup ini
            Text(vaccineName)
                .font(.headline)
                .foregroundStyle(.primary)

            // Text: tanggal + jam, sama buat semua record dalam grup ini
            if let dateGiven {
                Text(dateGiven.displayDateTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // HStack negative spacing: avatar dog numpuk kayak referensi
            HStack(spacing: -12) {
                ForEach(dogs, id: \.id) { dog in
                    DogStackedAvatar(dog: dog)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var vaccineName: String {
        records.first?.vaccine.displayName ?? ""
    }

    private var dateGiven: Date? {
        records.first?.dateGiven
    }

    private var dogs: [Dog] {
        records.compactMap(\.dog)
    }

    private var accessibilityLabel: String {
        let dateText = dateGiven?.displayDateTime ?? ""
        let dogNames = dogs.compactMap(\.name).joined(separator: ", ")

        if dogNames.isEmpty {
            return "\(vaccineName), given \(dateText)"
        }

        return "\(vaccineName), given \(dateText) to \(dogNames)"
    }
}

#Preview {
    VaccineRecordGroupRowView(records: [
        VaccineRecord(vaccine: .rabies, dateGiven: .now, dog: Dog(name: "Nathan")),
        VaccineRecord(vaccine: .rabies, dateGiven: .now, dog: Dog(name: "Berry"))
    ])
    .padding()
}
