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
        VStack(alignment: .leading, spacing: 8) {
            Text(displayName)
                .font(.title2.bold())

            Text(dog.breed.isEmpty ? "Breed not set" : dog.breed)
                .font(.body)

            Text("Born \(birthdayText)")
                .font(.body)

            Text("Vaccine Records")
                .font(.headline)
                .padding(.top, 4)

            if vaccineRecords.isEmpty {
                Text("No vaccine records")
                    .font(.body)
            } else {
                ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                    Text(vaccineRecordLine(for: vaccineRecord))
                        .font(.body)
                }
            }
        }
        .foregroundStyle(.black)
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Unnamed Dog" : trimmedName
    }

    private var birthdayText: String {
        guard let dateOfBirth = dog.dateOfBirth else {
            return "date not set"
        }

        return dateOfBirth.displayLongDate
    }

    private var vaccineRecords: [VaccineRecord] {
        (dog.vaccineRecords ?? []).sorted { $0.dateGiven > $1.dateGiven }
    }

    private func vaccineRecordLine(for vaccineRecord: VaccineRecord) -> String {
        let dateGiven = vaccineRecord.dateGiven.displayDate
        return "\u{2022} \(vaccineRecord.vaccine.displayName) — \(dateGiven)"
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
