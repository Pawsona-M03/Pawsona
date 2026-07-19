//
//  Date+PawsonaDisplay.swift
//  Pawsona
//

import Foundation

extension Date {
    /// Provides consistent date and time formatting across user-facing views and accessibility labels.
    ///
    /// Using these computed properties prevents display strings and accessibility labels from drifting apart.
    ///
    /// - Note: FormatStyle API is used instead of DateFormatter to align with modern Swift practices.

    /// Formats the date using abbreviated date and shortened time styles (e.g., "Jul 19, 2026, 7:30 PM").
    var displayDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    /// Formats the date using abbreviated date style and omitting the time (e.g., "Jul 19, 2026").
    var displayDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// Formats the date using long date style and omitting the time (e.g., "July 19, 2026").
    var displayLongDate: String {
        formatted(date: .long, time: .omitted)
    }
}
