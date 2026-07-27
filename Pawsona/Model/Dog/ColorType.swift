//
//  ColorType.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

enum ColorType: String, Codable, CaseIterable, Hashable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray
    
    var color: Color {
            switch self {
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .gray: return .gray
            }
        }
    
    var pastelColor: Color {
        switch self {
        case .red: return Color(hex: 0xF7D1D2)
        case .orange: return Color(hex: 0xF7E1CD)
        case .yellow: return Color(hex: 0xF7EEC4)
        case .green: return Color(hex: 0xCEEED6)
        case .blue: return Color(hex: 0xC4E1F7)
        case .purple: return Color(hex: 0xF0CFF5)
        case .pink: return Color(hex: 0xF7CFD7)
        case .gray: return Color(hex: 0xE5E4E5)
        }
    }
    
    /// Spoken name for the swatch — colour is the only thing distinguishing
    /// these buttons, so VoiceOver has nothing else to go on.
    var accessibilityName: String {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        case .gray: "Gray"
        }
    }
}
