//
//  DogGridItemView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct DogGridItemView: View {
    let dog: Dog
    var onDelete: (() -> Void)?

    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationLink(value: dog.id) {
            DogCardView(dog: dog)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "Delete \(dog.name ?? "Dog")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this dog? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        DogGridItemView(dog: Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green))
    }
}
