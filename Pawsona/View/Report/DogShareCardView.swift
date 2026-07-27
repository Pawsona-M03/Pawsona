//
//  DogShareCardView.swift
//  Pawsona
//

import SwiftUI
import UIKit

/// A fixed, landscape card layout rendered to a PNG by `DogShareCardRenderer`,
/// so a puppy's profile can be shared as a picture instead of a PDF attachment.
///
/// Point sizes are hard-coded here on purpose, as in `MarketplaceShareCardView`
/// and `DogPDFReportView`: the output is a raster on a fixed canvas, so it
/// cannot reflow for Dynamic Type and letting text styles scale it would only
/// break the layout. `DogDetailView` itself stays fully Dynamic Type driven.
///
/// The colour scheme is not read from the app here — `ImageRenderer` does not
/// inherit the presenting view's environment — so the caller injects the one
/// the user picked in `DogShareCardPickerView`.
struct DogShareCardView: View {
    static let width: CGFloat = 1500
    /// Fixed, not content-driven. Every field is bounded — the name and breed
    /// scale down rather than wrap, and the vaccine list is one row per type —
    /// so both appearances render at the same size and a well-vaccinated dog
    /// does not turn the card into a portrait poster.
    static let height: CGFloat = 1036
    private static let cornerRadius: CGFloat = 44
    /// One brown on both cards. `PrimaryBrown` lightens to salmon in dark mode,
    /// which would make the two cards read as different brands rather than the
    /// same card on two backgrounds, so it is pinned to its light value.
    private static let brandBrown = Color(
        UIColor(resource: .primaryBrown)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    )

    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            HStack(alignment: .top, spacing: 74) {
                photo

                details
                    // SwiftUI tops-aligns line boxes, but the design aligns the
                    // name's cap height with the top of the photo, so the text
                    // drops by the gap between the two.
                    .padding(.top, 21)
            }
            .padding(.top, 102)
            .padding(.leading, 173)
            .padding(.trailing, 176)

            Spacer(minLength: 0)
        }
        .frame(width: Self.width, height: Self.height, alignment: .topLeading)
        .background(Color(.appBackground))
        .clipShape(.rect(cornerRadius: Self.cornerRadius))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 43) {
            // ponytail: the artwork is 91x124, so it is upscaled ~3x here and
            // will read a little soft. Re-export it larger, or redraw it as a
            // `Shape`, if that ever shows on a shared card.
            Image(.ribbon)
                .resizable()
                .scaledToFit()
                .frame(width: 156, height: 213)

            Text("Pawsona")
                .font(.system(size: 86, weight: .bold))
                .foregroundStyle(Self.brandBrown)
                .padding(.top, 91)
        }
        .padding(.leading, 119)
    }

    private var photo: some View {
        DogPhotoView(dog: dog, placeholderIconHeight: 350)
            .frame(width: 502, height: 516)
            .clipShape(.rect(cornerRadius: 60))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading

            stats
                .padding(.top, 11)

            vaccineHistory
                .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One line when it fits, two when it does not. Side by side the name and
    /// breed compete for the same width and SwiftUI resolves that by truncating
    /// both — "Nova Scotia Duck Tolling Retriev…" — rather than letting
    /// `minimumScaleFactor` shrink them, so a long pair drops to a line each.
    private var heading: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 26) {
                name
                Text(verbatim: "|")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.secondary)
                breed
            }

            VStack(alignment: .leading, spacing: 2) {
                name
                breed
            }
        }
    }

    private var name: some View {
        Text(dog.displayName)
            .font(.system(size: 84, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    private var breed: some View {
        Text(dog.breedText)
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var stats: some View {
        // No trailing `Spacer` here. In an `HStack` a spacer competes with the
        // text for the proposed width, and `lineLimit(1)` resolves that by
        // truncating — "14 mo…". Sizing the stack to its content and pushing it
        // leading gives every column the width it asked for.
        HStack(alignment: .top, spacing: 74) {
            DogShareCardStat(title: "Age", value: ageText)
            DogShareCardStat(title: "Sex", value: sexText)
            DogShareCardStat(title: "Weight", value: weightText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The heading stays put when the dog has no records rather than being
    /// replaced by placeholder text: the card is a fixed canvas, so an empty
    /// section keeps every other card's layout identical.
    private var vaccineHistory: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Vaccine history")
                .font(.system(size: 50, weight: .bold))

            VStack(alignment: .leading, spacing: 3) {
                ForEach(vaccinations) { vaccination in
                    DogShareCardVaccineRow(vaccination: vaccination)
                }
            }
        }
    }

    /// One row per vaccine *type*, carrying the most recent dose. Listing every
    /// record instead would repeat the same seven names at every booster and
    /// push the card far past its fixed height; what a reader wants to know is
    /// which vaccines this dog has had and how current each one is.
    ///
    /// Bounded by `VaccineType.allCases`, which is what lets the height be fixed.
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

    private var ageText: String {
        PuppyAgeText.largestUnit(from: dog.dateOfBirth) ?? "Not set"
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 43, weight: .semibold))

            Text(value)
                .font(.system(size: 43))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct DogShareCardVaccineRow: View {
    let vaccination: DogShareCardVaccination

    var body: some View {
        HStack(spacing: 24) {
            Text(vaccination.vaccine.displayName)
                .font(.system(size: 43, weight: .semibold))

            Spacer(minLength: 24)

            Text(vaccination.dateGiven.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 43))
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
            dateOfBirth: Date(timeIntervalSinceNow: -60 * 60 * 24 * 430),
            weight: 5,
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
