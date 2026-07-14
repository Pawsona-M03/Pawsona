//
//  Dog.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class Dog {
    var id: UUID = UUID()
    var name: String? = ""
    var breed: String = ""
    var dateOfBirth: Date = Date.now
    var backgroundColor: ColorType = ColorType.blue

    init(
        id: UUID = UUID(),
        name: String = "",
        breed: String = "",
        dateOfBirth: Date = Date.now,
        backgroundColor: ColorType = ColorType.blue
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.backgroundColor = backgroundColor
    }
}

enum ColorType: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray
}
