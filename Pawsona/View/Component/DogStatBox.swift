//
//  DogStatBox.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 17/07/26.
//

import SwiftUI

struct DogStatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.cardSurface), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

#Preview {
    HStack(spacing: 12) {
        DogStatBox(title: "Age", value: "-")
        DogStatBox(title: "Sex", value: "-")
        DogStatBox(title: "Weight", value: "-")
    }
    .padding()
}
