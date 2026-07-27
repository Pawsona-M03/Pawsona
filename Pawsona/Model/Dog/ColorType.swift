//
//  ColorType.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

enum ColorType: String, Codable, CaseIterable, Hashable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray

    /// Fully saturated swatch, for the small circles in the colour picker.
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .gray: .gray
        }
    }

    /// Muted fill used behind photos and placeholders.
    ///
    /// Deliberately light-only: the same pastel renders in both appearances so
    /// a dog's colour reads identically everywhere, including in photos that
    /// bake it in and in shared cards. Anything drawn on top of one of these
    /// must therefore use a fixed dark foreground rather than `.primary`,
    /// which would go white in Dark Mode and disappear.
    var pastelColor: Color {
        switch self {
        case .red: Color(.pastelRed)
        case .orange: Color(.pastelOrange)
        case .yellow: Color(.pastelYellow)
        case .green: Color(.pastelGreen)
        case .blue: Color(.pastelBlue)
        case .purple: Color(.pastelPurple)
        case .pink: Color(.pastelPink)
        case .gray: Color(.pastelGray)
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
