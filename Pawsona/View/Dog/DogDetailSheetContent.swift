//
//  DogDetailSheetContent.swift
//  Pawsona
//

import SwiftData
import SwiftUI

struct DogDetailSheetContent: View {
    let dog: Dog
    let containerHeight: CGFloat
    let sheetCornerRadius: CGFloat

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            HStack(spacing: 12) {
                DogStatBox(title: "Age", value: ageText)
                DogStatBox(title: "Sex", value: sexText)
                DogStatBox(title: "Weight", value: weightText)
            }
            .padding(.horizontal)

            NavigationLink {
                DogVaccinationRecordView(dog: dog)
            } label: {
                HStack {
                    Text("Vaccination Record")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(vaccineRecordCount) entries")
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.quinary, in: .rect(cornerRadius: 14))
                .background(.background, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Spacer(minLength: 40)
        }
        .padding(.bottom, 24)
        .frame(
            maxWidth: .infinity,
            minHeight: max(0, containerHeight - sheetCornerRadius),
            alignment: .top
        )
        .background {
            Image(.pawsBg)
                .resizable()
                .scaledToFill()
        }
        .background(.background)
        .clipShape(.rect(topLeadingRadius: sheetCornerRadius, topTrailingRadius: sheetCornerRadius))
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var breedText: String {
        dog.breed.isEmpty ? "Breed not set" : dog.breed
    }

    private var ageText: String {
        guard let age = dog.age else { return "-" }
        return "\(age)"
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

    private var vaccineRecordCount: Int {
        dog.vaccineRecords?.count ?? 0
    }
}
