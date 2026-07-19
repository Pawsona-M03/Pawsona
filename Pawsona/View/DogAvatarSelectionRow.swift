//
//  DogAvatarSelectionRow.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftUI
import UIKit

/// Satu avatar puppy yang bisa dipilih (multi-select), foto bulat + nama di bawahnya.
struct DogAvatarSelectionRow: View {
    let dog: Dog
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        // Button: seluruh avatar+nama jadi satu tombol, bukan .onTapGesture
        Button(action: toggle) {
            // VStack: foto di atas, nama di bawah
            VStack(spacing: 5) {
                // ZStack: numpuk foto dog + ring seleksi di atasnya
                ZStack {
                    photo
                        .clipShape(.circle)
                        .frame(width: 56, height: 56)

                    // Circle: ring penanda kepilih, cuma muncul kalau isSelected
                    if isSelected {
                        Circle()
                            .stroke(.tint, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }
                }

                // Text: nama dog, fallback kalau belum diisi
                Text(dog.name ?? "Puppy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // fungsi: pilih foto dog kalau ada, atau ikon default kalau belum ada foto
    @ViewBuilder
    private var photo: some View {
        if let photoData = dog.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "pawprint.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DogAvatarSelectionRow(dog: Dog(name: "Piere"), isSelected: true) {}
}
