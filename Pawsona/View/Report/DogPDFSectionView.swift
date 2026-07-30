//
//  DogPDFSectionView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

struct DogPDFSectionView: View {
    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Color("PrimaryBrown"))

                Text(dog.breed.isEmpty ? "Breed not set" : dog.breed)
                    .font(.body)
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 12) {
                DogPDFDetailPill(title: "Born", value: birthdayText)
                DogPDFDetailPill(title: "Sex", value: sexText)
                DogPDFDetailPill(title: "Weight", value: weightText)
                DogPDFDetailPill(title: "Vaccines", value: vaccineRecords.count.formatted(.number))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vaccine Records")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryBrown"))

                if vaccineRecords.isEmpty {
                    Text("No vaccine records")
                        .font(.body)
                        .foregroundStyle(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                            Text(vaccineRecordLine(for: vaccineRecord))
                                .font(.body)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.black)
        .background(Color("PrimaryBrown").opacity(0.06))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color("PrimaryBrown"))
                .frame(width: 4)
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Unnamed Dog" : trimmedName
    }

    private var birthdayText: String {
        guard let dateOfBirth = dog.dateOfBirth else {
            return "date not set"
        }

        return dateOfBirth.formatted(date: .long, time: .omitted)
    }

    private var sexText: String {
        switch dog.sex {
        case .male: "Male"
        case .female: "Female"
        case nil: "-"
        }
    }

    private var weightText: String {
        guard let weight = dog.weight else { return "-" }
        return weight.formatted(.number.precision(.fractionLength(1)))
    }

    private var vaccineRecords: [VaccineRecord] {
        (dog.vaccineRecords ?? []).sorted { $0.dateGiven > $1.dateGiven }
    }

    private func vaccineRecordLine(for vaccineRecord: VaccineRecord) -> String {
        let dateGiven = vaccineRecord.dateGiven.formatted(date: .abbreviated, time: .omitted)
        return "\u{2022} \(vaccineRecord.vaccineNames) — \(dateGiven)"
    }
}

private struct DogPDFDetailPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(Color("PrimaryBrown"))

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white)
        .clipShape(.rect(cornerRadius: 10))
    }
}

#Preview {
    DogPDFSectionView(
        dog: Dog(
            name: "Berry",
            breed: "Labrador Retriever",
            dateOfBirth: .now
        )
    )
    .padding()
    .background(.white)
}
