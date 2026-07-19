//
//  NotificationPermissionBanner.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 20/07/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Shown on the reminders screen when notification permission is denied, so
/// scheduling doesn't fail silently — it points the user to Settings.
struct NotificationPermissionBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text("Notifications are off")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Turn on notifications in Settings to be reminded at the right time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let settingsURL {
                    Button("Open Settings") {
                        openURL(settingsURL)
                    }
                    .font(.subheadline)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    private var settingsURL: URL? {
        #if canImport(UIKit)
        URL(string: UIApplication.openSettingsURLString)
        #else
        nil
        #endif
    }
}

#Preview {
    NotificationPermissionBanner()
        .padding()
}
