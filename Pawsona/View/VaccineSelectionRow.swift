//
//  VaccineSelectionRow.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftUI

/// Satu baris vaccine yang bisa dipilih (single-select, gaya radio button).
struct VaccineSelectionRow: View {
    let vaccine: VaccineType
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        // Button: bungkus seluruh baris biar bisa di-tap & kebaca VoiceOver sebagai tombol
        Button(action: select) {
            // HStack: nama vaksin di kiri, bulatan radio di kanan
            HStack {
                // Text: nama vaksin, pakai text style biar Dynamic Type jalan
                Text(vaccine.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                // Image(systemName:): bulatan radio, isi kalau kepilih, kosong kalau enggak
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                   // .foregroundStyle(isSelected ? .tint : .secondary)
            }
            // contentShape: biar area kosong (bukan cuma teks/ikon) ikut bisa di-tap
            .contentShape(.rect)
        }
        // accessibility: tambahin trait "selected" kalau lagi kepilih
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VaccineSelectionRow(vaccine: .parvovirus, isSelected: true) {}
    VaccineSelectionRow(vaccine: .rabies, isSelected: false) {}
}
