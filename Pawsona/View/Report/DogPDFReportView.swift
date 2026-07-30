//
//  DogPDFReportView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

/// A fixed, print-oriented layout rendered into `PDFGenerator`'s output.
struct DogPDFReportView: View {
    static let pageWidth: CGFloat = 612

    let dogs: [Dog]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            DogPDFReportHeaderView(dogCount: dogs.count)

            DogPDFReportContentView(dogs: dogs)
        }
        .padding(36)
        .frame(width: Self.pageWidth, alignment: .leading)
        .foregroundStyle(.black)
        .background(.white)
    }
}

private struct DogPDFReportHeaderView: View {
    let dogCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("PrimaryBrown").opacity(0.22), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pawsona")
                        .font(.title.bold())
                        .foregroundStyle(Color("PrimaryBrown"))

                    Text("Dog Health Report")
                        .font(.headline)
                        .foregroundStyle(.gray)
                }

                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("PrimaryBrown").opacity(0.08))
            .clipShape(.rect(cornerRadius: 18))

            HStack(spacing: 16) {
                DogPDFHeaderMetadataItem(title: "Generated", value: Date.now.formatted(date: .long, time: .omitted))
                DogPDFHeaderMetadataItem(title: "Dogs", value: dogCount.formatted(.number))
            }

            Rectangle()
                .fill(Color("PrimaryBrown").opacity(0.3))
                .frame(height: 1)
        }
    }
}

private struct DogPDFHeaderMetadataItem: View {
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
    }
}

private struct DogPDFReportContentView: View {
    let dogs: [Dog]

    var body: some View {
        if dogs.isEmpty {
            DogPDFEmptyReportView()
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(dogs, id: \.id) { dog in
                    DogPDFSectionView(dog: dog)
                }
            }
        }
    }
}

private struct DogPDFEmptyReportView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No dogs to report")
                .font(.title3.bold())

            Text("Add a puppy profile to include health details and vaccine records in this report.")
                .font(.body)
                .foregroundStyle(.gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("PrimaryBrown").opacity(0.08))
        .clipShape(.rect(cornerRadius: 14))
    }
}

#Preview {
    DogPDFReportView(
        dogs: [
            Dog(name: "Berry", breed: "Labrador Retriever", dateOfBirth: .now)
        ]
    )
}
