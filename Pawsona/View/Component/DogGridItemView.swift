//
//  DogGridItemView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct DogGridItemView: View {
    let dog: Dog

    var body: some View {
        // Routing by the model rather than its UUID: the destination used to
        // re-fetch the dog by id inside the navigationDestination closure, which
        // both ran a store fetch and mutated observable state during view-body
        // evaluation.
        NavigationLink(value: dog) {
            DogCardView(dog: dog)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Shows dog details")
    }

    private var accessibilityLabel: String {
        var label = "\(dog.displayName), \(dog.breedText)"
        if let ageText = dog.ageText {
            label += ", \(ageText)"
        }
        return label
    }
}

#Preview {
    NavigationStack {
        DogGridItemView(dog: Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green))
    }
}
