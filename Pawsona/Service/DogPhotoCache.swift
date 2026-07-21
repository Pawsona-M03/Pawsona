//
//  DogPhotoCache.swift
//  Pawsona
//

import UIKit

/// Decoded dog photos, keyed by dog.
///
/// `UIImage(data:)` was being called straight from `body` in the grid cells,
/// reminder rows, and selection avatars — the views SwiftUI re-evaluates most,
/// and the ones inside lazy stacks where scrolling drives repeated evaluation.
/// Because `photoData` uses `.externalStorage`, each of those calls could also
/// fault the blob back off disk, to produce a full-resolution decode for a 50pt
/// avatar.
///
/// Entries are held by `NSCache`, so the system evicts them under memory
/// pressure rather than this growing without bound.
enum DogPhotoCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // Roughly a hundred decoded avatars; the real limit is the eviction.
        cache.countLimit = 100
        return cache
    }()

    /// The decoded photo for this dog, decoding and caching on first ask.
    ///
    /// The key folds in the data's size so that replacing a dog's photo
    /// invalidates the entry — the dog's id alone would keep serving the old
    /// image until eviction.
    static func image(for dog: Dog) -> UIImage? {
        guard let photoData = dog.photoData else { return nil }

        let key = "\(dog.id.uuidString)-\(photoData.count)" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let image = UIImage(data: photoData) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
