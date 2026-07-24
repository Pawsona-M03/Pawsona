//
//  DogSortOption.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import Foundation

enum DogSortOption: String, CaseIterable, Identifiable {
    case dateAdded
    case name
    case breed

    var id: Self { self }

    var title: String {
        switch self {
        case .dateAdded: "Date Added"
        case .name: "Name"
        case .breed: "Breed"
        }
    }

    /// The direction this field should start in when it becomes the active sort.
    var defaultDirection: DogSortDirection {
        switch self {
        case .dateAdded: .descending
        case .name, .breed: .ascending
        }
    }

    func sortDescriptor(direction: DogSortDirection) -> SortDescriptor<Dog> {
        switch self {
        case .dateAdded: SortDescriptor(\Dog.createdAt, order: direction.sortOrder)
        case .name: SortDescriptor(\Dog.name, order: direction.sortOrder)
        case .breed: SortDescriptor(\Dog.breed, order: direction.sortOrder)
        }
    }

    /// Direction labels read differently per field — "Newest First" makes sense
    /// for a date, "A to Z" for text — so the copy is chosen here.
    func directionTitle(for direction: DogSortDirection) -> String {
        switch self {
        case .dateAdded:
            switch direction {
            case .ascending: "Oldest First"
            case .descending: "Newest First"
            }
        case .name, .breed:
            switch direction {
            case .ascending: "A to Z"
            case .descending: "Z to A"
            }
        }
    }
}
