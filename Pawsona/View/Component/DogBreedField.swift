//
//  DogBreedField.swift
//  Pawsona
//

import SwiftUI

struct DogBreedField: View {
    @Binding var breed: String

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
    }
}

#Preview {
    DogBreedField(breed: .constant(""))
}
