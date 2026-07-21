//
//  VaccineRecordDraft.swift
//  Pawsona
//

import Foundation

/// Editable form values for creating or updating a `VaccineRecord`, passed
/// between `VaccineRecordFormView` and `VaccineViewModel`.
///
/// Mirrors `DogDraft`. It replaces a six-parameter view-model call and a
/// four-value unlabelled closure, both of which had already been called with
/// their arguments in different orders at different call sites.
struct VaccineRecordDraft {
    var vaccines: [VaccineType] = []
    var dateGiven: Date = .now
    var dogs: [Dog] = []
    var notes: String?
}
