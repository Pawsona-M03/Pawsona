//
//  DeleteConfirmation.swift
//  Pawsona
//

import SwiftUI

extension View {
    /// Presents the app's delete-confirmation alert for the item bound to `item`.
    ///
    /// Long-press deletes across the app set a "pending deletion" item; this
    /// modifier turns that into the same native alert the edit forms use, then
    /// calls `perform` only if the user confirms. Dismissing — by Cancel or
    /// otherwise — clears `item`.
    func deleteConfirmation<Item>(
        _ item: Binding<Item?>,
        title: String,
        message: @escaping (Item) -> String? = { _ in nil },
        confirmTitle: String = "Delete",
        perform: @escaping (Item) -> Void
    ) -> some View {
        let isPresented = Binding(
            get: { item.wrappedValue != nil },
            set: { presented in
                if !presented { item.wrappedValue = nil }
            }
        )

        return alert(
            title,
            isPresented: isPresented,
            presenting: item.wrappedValue
        ) { value in
            Button(confirmTitle, role: .destructive) { perform(value) }
            // Opt out of the app's brown tint so Cancel reads as a plain,
            // standard alert button rather than a branded one.
            Button("Cancel", role: .cancel) {}
                .tint(.primary)
        } message: { value in
            if let message = message(value) {
                Text(message)
            }
        }
    }
}
