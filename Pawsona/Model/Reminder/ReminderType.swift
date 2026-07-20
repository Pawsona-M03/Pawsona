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

    /// Accent used for the type's dot, icon, and card title (per the hifi).
    var color: Color {
        switch self {
        case .vitamin: .orange
        case .medicine: .cyan
        case .vaccine: .green
        case .others: .purple
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
