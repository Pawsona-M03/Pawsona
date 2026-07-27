//
//  DogShareCardView.swift
//  Pawsona
//

import SwiftUI

/// A fixed, landscape "trust card" layout rendered to a PNG by
/// `DogShareCardRenderer`, so a puppy's profile can be shared as a picture
/// instead of a PDF attachment.
///
/// Point sizes are hard-coded here on purpose, as in `MarketplaceShareCardView`
/// and `DogPDFReportView`: the output is a raster on a fixed canvas, so it
/// cannot reflow for Dynamic Type and letting text styles scale it would only
/// break the layout. `DogDetailView` itself stays fully Dynamic Type driven.
///
/// The colour scheme is not read from the app here — `ImageRenderer` does not
/// inherit the presenting view's environment — so the caller injects it and the
/// card comes out matching whatever appearance the user is in.
struct DogShareCardView: View {
    static let width: CGFloat = 1500
    private static let minimumHeight: CGFloat = 950
    private static let cornerRadius: CGFloat = 48

    @Environment(\.colorScheme) private var colorScheme

    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 56) {
            Image(.pawsonaLogo)
                .resizable()
                .scaledToFit()
                .frame(height: 110)

            HStack(alignment: .top, spacing: 56) {
                photo

                VStack(alignment: .leading, spacing: 0) {
                    heading

                    stats
                        .padding(.top, 18)

                    vaccineHistory
                        .padding(.top, 56)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(64)
        .frame(width: Self.width, alignment: .topLeading)
        .frame(minHeight: Self.minimumHeight, alignment: .topLeading)
        .background {
            Color(.appBackground)

            // The light artwork is opaque and the dark one is transparent, but
            // both draw the same way and the colour behind covers the gap.
            Image(colorScheme == .dark ? .pawsBgDark : .pawsBg)
                .resizable()
                .scaledToFill()
        }
        .clipShape(.rect(cornerRadius: Self.cornerRadius))
    }

    private var photo: some View {
        DogPhotoView(dog: dog, placeholderIconHeight: 320)
            .frame(width: 520, height: 520)
            .clipShape(.rect(cornerRadius: 32))
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color(.primaryBrown), lineWidth: 14)
            }
    }

    private var heading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(dog.displayName)
                .font(.system(size: 88, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Text(verbatim: "|")
                .font(.system(size: 66, weight: .thin))
                .foregroundStyle(.secondary)

            Text(dog.breedText)
                .font(.system(size: 52))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var stats: some View {
        HStack(alignment: .firstTextBaseline, spacing: 64) {
            DogShareCardStat(title: "Age", value: dog.ageText ?? "Not set")
            DogShareCardStat(title: "Sex", value: sexText)
            DogShareCardStat(title: "Weight", value: weightText)
        }
    }

    private var vaccineHistory: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Vaccine History")
                .font(.system(size: 64, weight: .bold))

            if vaccinations.isEmpty {
                Text("No vaccine records yet.")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vaccinations) { vaccination in
                        DogShareCardVaccineRow(vaccination: vaccination)
                    }
                }
            }
        }
    }

    /// One row per vaccine rather than per record: a single visit can cover four
    /// vaccines, and the card lists them the way a vet's booklet does.
    ///
    /// ponytail: uncapped. A dog with dozens of doses makes a very tall card;
    /// add a "+N more" cutoff if that ever turns up in real data.
    private var vaccinations: [DogShareCardVaccination] {
        (dog.vaccineRecords ?? [])
            .flatMap { record in
                record.vaccines.map {
                    DogShareCardVaccination(
                        recordID: record.id,
                        vaccine: $0,
                        dateGiven: record.dateGiven
                    )
                }
            }
            .sorted { $0.dateGiven > $1.dateGiven }
    }

    private var sexText: String {
        switch dog.sex {
        case .male: "M"
        case .female: "F"
        case nil: "Not set"
        }
    }

    private var weightText: String {
        guard let weight = dog.weight else { return "Not set" }
        return "\(weight.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }
}

/// A single dose on the card: one vaccine from one record, flattened so each
/// gets its own line and date.
private struct DogShareCardVaccination: Identifiable {
    let recordID: UUID
    let vaccine: VaccineType
    let dateGiven: Date

    var id: String { "\(recordID)-\(vaccine.rawValue)" }
}

private struct DogShareCardStat: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 40))
        }
    }
}

private struct DogShareCardVaccineRow: View {
    let vaccination: DogShareCardVaccination

    var body: some View {
        HStack(spacing: 24) {
            Text(vaccination.vaccine.displayName)
                .font(.system(size: 36))

            Spacer(minLength: 24)

            Text(vaccination.dateGiven.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Light") {
    DogShareCardView(dog: .shareCardPreview)
        .scaleEffect(0.25)
}

#Preview("Dark") {
    DogShareCardView(dog: .shareCardPreview)
        .scaleEffect(0.25)
        .environment(\.colorScheme, .dark)
}

private extension Dog {
    static var shareCardPreview: Dog {
        let dog = Dog(
            name: "Nathan",
            breed: "Golden Retriever",
            backgroundColor: .green,
            dateOfBirth: Date(timeIntervalSinceNow: -60 * 60 * 24 * 730),
            weight: 6,
            sex: .male
        )
        dog.vaccineRecords = [
            VaccineRecord(
                vaccines: [.parvovirus, .hepatitis, .distemper, .leptospira],
                dateGiven: .now
            )
        ]
        return dog
    }
}
