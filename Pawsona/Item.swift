//
//  Item.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 11/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
