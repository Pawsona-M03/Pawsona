//
//  VaccineRecord.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class VaccineRecord{
    var id: UUID
    var vaccineList: VaccineType
    var date: Date
    var dogList: [Dog]
    
    init(id: UUID, vaccineList: VaccineType, date: Date, dogList: [Dog]) {
        self.id = id
        self.vaccineList = vaccineList
        self.date = date
        self.dogList = dogList
    }
}

enum VaccineType{
    case parvovirus
    case hepatitis
    case distamper
    case leptospira
    case rabies
    case parainfluenza
    case bordetella
}
