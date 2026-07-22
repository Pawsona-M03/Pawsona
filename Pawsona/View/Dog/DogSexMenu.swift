//
//  DogSexMenu.swift
//  Pawsona
//

import SwiftUI

struct DogSexMenu: View {
    @Binding var sex: Sex?
    let rowHeight: CGFloat

    var body: some View {
        Menu {
            Button("Male") {
                sex = .male
            }

            Button("Female") {
                sex = .female
            }

            Button("Not Set") {
                sex = nil
            }
        } label: {
            HStack {
                Text(sex.displayName)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .frame(minHeight: rowHeight)
            .contentShape(.rect)
        }
        .accessibilityLabel("Dog gender")
    }
}

private extension Optional where Wrapped == Sex {
    var displayName: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        case nil:
            "Gender"
        }
    }
}

#Preview {
    DogSexMenu(sex: .constant(.female), rowHeight: 60)
}
