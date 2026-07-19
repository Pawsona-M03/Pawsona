//
//  DogListContentView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct DogListContentView: View {
    let filteredDogs: [Dog]
    let searchText: String
    let columns: [GridItem]

    var body: some View {
        Group {
            if filteredDogs.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Dogs Yet",
                        systemImage: "pawprint",
                        description: Text("Add a dog to start tracking reminders and vaccines.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(filteredDogs, id: \.id) { dog in
                            DogGridItemView(dog: dog)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background {
            Image(.pawsBg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.8)
        }
    }
}

#Preview {
    DogListContentView(
        filteredDogs: [Dog(name: "Berry", breed: "Labrador Retriever", backgroundColor: .green)],
        searchText: "",
        columns: [GridItem(.flexible()), GridItem(.flexible())]
    )
}
