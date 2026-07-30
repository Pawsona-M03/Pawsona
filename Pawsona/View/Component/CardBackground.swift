//
//  CardBackground.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 22/07/26.
//

import SwiftUI

/// The app's one card surface: `cardSurface` on `appBackground`, no shadow.
///
/// The two colours are far enough apart in both appearances to separate a card
/// from the page on their own, so nothing here casts a shadow — matching the
/// reminder list, whose rows are plain `List` rows.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(Color(.cardSurface), in: .rect(cornerRadius: cornerRadius))
    }
}

extension View {
    /// Applies the app's standard card surface.
    func cardBackground(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}
