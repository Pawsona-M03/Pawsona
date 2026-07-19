//
//  Image+Data.swift
//  Pawsona
//

import SwiftUI
import UIKit

extension Image {
    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
    }
}
