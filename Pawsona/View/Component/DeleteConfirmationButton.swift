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
        Button(role: .destructive) {
            isShowingConfirmation = true
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        // A native alert: the centred modal that asks for a deliberate second
        // tap before the destructive action runs.
        .alert(title, isPresented: $isShowingConfirmation) {
            Button("Delete", role: .destructive, action: action)
            // Opt out of the app's brown tint so Cancel reads as a plain,
            // standard alert button rather than a branded one.
            Button("Cancel", role: .cancel) {}
                .tint(.primary)
        } message: {
            Text(message)
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
