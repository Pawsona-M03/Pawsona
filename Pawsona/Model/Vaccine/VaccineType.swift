//
//  VaccineType.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

enum VaccineType: String, Codable, CaseIterable {
    case parvovirus
    case hepatitis
    case distemper
    case leptospira
    case rabies
    case parainfluenza
    case bordetella

    var displayName: String {
        switch self {
        case .parvovirus:
            "Parvovirus"
        case .hepatitis:
            "Hepatitis"
        case .distemper:
            "Distemper"
        case .leptospira:
            "Leptospira"
        case .rabies:
            "Rabies"
        case .parainfluenza:
            "Parainfluenza"
        case .bordetella:
            "Bordetella"
        }
    }
}
