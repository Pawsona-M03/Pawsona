//
//  DeleteConfirmationButton.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 22/07/26.
//

import SwiftUI

/// The app's one destructive form action: a centred delete button that asks for
/// confirmation before calling back.
///
/// Placement is deliberately the caller's job. The reminder form drops this into
/// a `Form` section, which supplies the white row on its own, while the dog and
/// vaccine forms wrap it in `cardBackground()` to reach the same surface at the
/// corner radius the rest of that screen uses.
struct DeleteConfirmationButton: View {
    let title: String
    let message: String
    let action: () -> Void

    @State private var isShowingConfirmation = false

    var body: some View {
        Button(title, role: .destructive) {
            isShowingConfirmation = true
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        // A popover anchors the confirmation to the button itself; a
        // confirmationDialog would slide up from the bottom of the screen
        // instead.
        .popover(isPresented: $isShowingConfirmation, arrowEdge: .bottom) {
            VStack(spacing: 16) {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                Button(title, role: .destructive, action: action)
                    .buttonStyle(.borderedProminent)
                    // Otherwise it inherits the app's brown tint and stops
                    // reading as destructive.
                    .tint(.red)
            }
            .padding()
            .frame(idealWidth: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    Form {
        Section {
            DeleteConfirmationButton(
                title: "Delete Reminder",
                message: "This also cancels its notification. You can't undo this."
            ) {}
        }
    }
}
