//
//  TestSupport.swift
//  PawsonaTests
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
@testable import Pawsona

enum TestSupport {
    static func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Dog.self, Reminder.self, VaccineRecord.self,
            configurations: config
        )
        return ModelContext(container)
    }
}
