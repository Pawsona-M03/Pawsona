//
//  DogListContentView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftData
import SwiftUI

struct DogListContentView: View {
    @Query private var filteredDogs: [Dog]
    let searchText: String
    let columns: [GridItem]
    var onDelete: ((UUID) -> Void)?

    init(sortOption: DogSortOption, searchText: String, columns: [GridItem], onDelete: ((UUID) -> Void)? = nil) {
        self.searchText = searchText
        self.columns = columns
        self.onDelete = onDelete

        let predicate: Predicate<Dog>
        if searchText.isEmpty {
            predicate = #Predicate<Dog> { _ in true }
        } else {
            predicate = #Predicate<Dog> { dog in
                dog.name?.localizedStandardContains(searchText) == true
                || dog.breed.localizedStandardContains(searchText) == true
            }
        }

        _filteredDogs = Query(filter: predicate, sort: [sortOption.sortDescriptor])
    }

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
                            DogGridItemView(dog: dog) {
                                onDelete?(dog.id)
                            }
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
        sortOption: .dateAdded,
        searchText: "",
        columns: [GridItem(.flexible()), GridItem(.flexible())]
    )
}
