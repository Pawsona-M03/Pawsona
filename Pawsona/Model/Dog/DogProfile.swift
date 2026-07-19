//
//  DogProfile.swift
//  Pawsona
//

import Foundation

/// The editable fields of a dog, passed between `DogFormView` and `DogViewModel`.
struct DogProfile {
    var name = ""
    var breed = ""
    var dateOfBirth = Date.now
    var backgroundColor = ColorType.blue
    var photoData: Data?
}
