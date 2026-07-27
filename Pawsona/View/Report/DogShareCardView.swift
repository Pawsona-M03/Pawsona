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
    /// Fixed, not content-driven. Every field on the card is bounded — the name
    /// and breed scale down rather than wrap, and the vaccine list is one row
    /// per type — so the card can keep the same landscape shape for every dog
    /// instead of growing into a portrait poster for a well-vaccinated one.
    static let height: CGFloat = 1050
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
        .frame(width: Self.width, height: Self.height, alignment: .topLeading)
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

    /// Name and breed sit on their own lines rather than sharing one. Side by
    /// side they compete for the same width, and SwiftUI resolves that by
    /// truncating both — "Nova Scotia Duck Tolling Retriev…" — instead of
    /// letting `minimumScaleFactor` shrink them. A line each gives the full
    /// width to one string, so long names scale down and stay readable.
    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dog.displayName)
                .font(.system(size: 88, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Text(dog.breedText)
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(alignment: .firstTextBaseline, spacing: 64) {
            DogShareCardStat(title: "Age", value: ageText)
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

    /// One row per vaccine *type*, carrying the most recent dose. Listing every
    /// record instead would repeat the same seven names at every booster and
    /// push the card past 5000px tall; what a reader actually wants to know is
    /// which vaccines this dog has and how current each one is.
    ///
    /// Bounded by `VaccineType.allCases`, which is what lets the card keep a
    /// fixed height.
    private var vaccinations: [DogShareCardVaccination] {
        let latestDates = (dog.vaccineRecords ?? []).reduce(into: [VaccineType: Date]()) { dates, record in
            for vaccine in record.vaccines {
                dates[vaccine] = max(dates[vaccine] ?? .distantPast, record.dateGiven)
            }
        }

        return latestDates
            .map { DogShareCardVaccination(vaccine: $0.key, dateGiven: $0.value) }
            .sorted { $0.dateGiven == $1.dateGiven ? $0.id < $1.id : $0.dateGiven > $1.dateGiven }
    }

    /// Months rather than the app's "1 year, 2 months old": that phrasing wraps
    /// onto a second line here and knocks the Age/Sex/Weight row out of
    /// alignment, and months is how a puppy's age gets talked about anyway.
    private var ageText: String {
        guard let dateOfBirth = dog.dateOfBirth else { return "Not set" }

        let months = max(0, Calendar.current.dateComponents([.month], from: dateOfBirth, to: .now).month ?? 0)
        return "\(months) \(months == 1 ? "month" : "months")"
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

/// One line on the card: a vaccine and the date it was most recently given.
private struct DogShareCardVaccination: Identifiable {
    let vaccine: VaccineType
    let dateGiven: Date

    var id: String { vaccine.rawValue }
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
