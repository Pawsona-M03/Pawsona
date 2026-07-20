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
        NavigationLink(value: dog.id) {
            DogCardView(dog: dog)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Shows dog details")
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var breedText: String {
        dog.breed.isEmpty ? "Breed not set" : dog.breed
    }

    private var ageText: String? {
        guard let age = dog.age else { return nil }
        return age == 1 ? "1 year old" : "\(age) years old"
    }

    private var accessibilityLabel: String {
        var label = "\(displayName), \(breedText)"
        if let ageText {
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
