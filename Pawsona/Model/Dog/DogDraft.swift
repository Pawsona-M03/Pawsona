//
//  DogDraft.swift
//  Pawsona
//

import Foundation

/// Editable form values for creating or updating a `Dog`, passed between
/// `DogFormView` and `DogViewModel` so neither needs a long parameter list.
struct DogDraft {
    var name = ""
    var breed = ""
    var dateOfBirth = Date.now
    var backgroundColor = ColorType.blue
    var photoData: Data?
}
