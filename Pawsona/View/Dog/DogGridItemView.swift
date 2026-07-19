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
    }
}

#Preview {
    NavigationStack {
        DogGridItemView(dog: Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green))
    }
}
