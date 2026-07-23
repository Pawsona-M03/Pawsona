//
//  DogBreedField.swift
//  Pawsona
//

import SwiftUI

struct DogBreedField: View {
    @Binding var breed: String
    let rowHeight: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            if breed.isEmpty {
                HStack(spacing: 2) {
                    Text("Breed")
                        .foregroundStyle(.secondary)
                    Text("*")
                        .foregroundStyle(.red)
                }
                .allowsHitTesting(false)
            }

            TextField("", text: $breed)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Dog breed")
        }
        .frame(minHeight: rowHeight)
    }
}

#Preview {
    DogBreedField(breed: .constant(""), rowHeight: 60)
}
