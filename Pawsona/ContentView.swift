//
//  ContentView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 11/07/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Puppy", systemImage: "dog") {
                DogListView()
            }
            
            Tab("Reminder", systemImage: "bell") {
                
            }
            
            Tab("Vaccine", systemImage: "syringe") {
                
            }
            
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(for: Dog.self, inMemory: true)
}
