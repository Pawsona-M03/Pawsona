//
//  ReminderType.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftUI

enum ReminderType: String, Codable, CaseIterable {
    case medicine
    case vitamin
    case vaccine
    case others
}

extension ReminderType {
    var displayName: String { rawValue.capitalized }

    /// Accent used for the type's dot and icon (per the hifi). Deliberately not
    /// used for title text: these tints sit at roughly 2:1 against a card, well
    /// under the 4.5:1 text minimum, so titles stay on `.primary`.
    var color: Color {
        switch self {
        case .vitamin: Color(.vitamin)
        case .medicine: Color(.medicine)
        case .vaccine: Color(.vaccine)
        case .others: Color(.others)
        }
    }

    var icon: String {
        switch self {
        case .medicine, .vitamin: "pills.fill"
        case .vaccine: "syringe.fill"
        case .others: "bell.fill"
        }
    }
}
