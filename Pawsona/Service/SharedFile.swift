//
//  SharedFile.swift
//  Pawsona
//

import Foundation

/// A file waiting to be shared, wrapped so it can drive `.sheet(item:)`.
///
/// `URL` is not `Identifiable`, and conforming it retroactively would claim a
/// conformance that isn't ours to give.
struct SharedFile: Identifiable {
    let id = UUID()
    let url: URL
}
