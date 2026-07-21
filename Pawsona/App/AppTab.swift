//
//  AppTab.swift
//  Pawsona
//

/// The app's three top-level tabs. Named so code that needs to switch tabs —
/// importing a shared dog, for instance — can say which one it means.
enum AppTab: Hashable {
    case puppy
    case reminder
    case vaccine
}
