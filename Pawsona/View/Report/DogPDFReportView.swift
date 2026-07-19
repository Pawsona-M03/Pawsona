//
//  DogPDFReportView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

/// A fixed, print-oriented layout rendered into `PDFGenerator`'s output — colors are
/// intentionally hardcoded to black-on-white since a PDF page has no Dark Mode to adapt to.
struct DogPDFReportView: View {
    static let pageWidth: CGFloat = 612

    let dogs: [Dog]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Pawsona Dog Report")
                .font(.largeTitle.bold())

            Text(Date.now.displayLongDate)
                .font(.subheadline)
                .foregroundStyle(.gray)

            if dogs.isEmpty {
                Text("No dogs to report.")
                    .font(.body)
                    .foregroundStyle(.black)
            } else {
                ForEach(dogs, id: \.id) { dog in
                    DogPDFSectionView(dog: dog)
                }
            }
        }
        .padding(32)
        .frame(width: Self.pageWidth, alignment: .leading)
        .foregroundStyle(.black)
        .background(.white)
    }
}

#Preview {
    DogPDFReportView(
        dogs: [
            Dog(name: "Berry", breed: "Labrador Retriever", dateOfBirth: .now)
        ]
    )
}
