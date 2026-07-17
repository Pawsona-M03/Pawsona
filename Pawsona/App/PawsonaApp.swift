//
//  PawsonaApp.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 11/07/26.
//

import SwiftData
import SwiftUI

@main
struct PawsonaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Dog.self,
            Reminder.self,
            VaccineRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
