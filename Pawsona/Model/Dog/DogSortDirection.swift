//
//  DogSortDirection.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import Foundation

/// The direction a `DogSortOption` is applied in. Kept separate from the sort
/// field so any field can be viewed ascending or descending.
enum DogSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: Self { self }

    var sortOrder: SortOrder {
        switch self {
        case .ascending: .forward
        case .descending: .reverse
        }
    }
}
