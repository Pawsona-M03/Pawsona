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

    var sortDescriptor: SortDescriptor<Dog> {
        switch self {
        case .dateAdded: SortDescriptor(\Dog.createdAt, order: .reverse)
        case .name: SortDescriptor(\Dog.name, order: .forward)
        case .breed: SortDescriptor(\Dog.breed, order: .forward)
        }
    }
}
