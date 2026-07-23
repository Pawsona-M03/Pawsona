//
//  DogSexMenu.swift
//  Pawsona
//

import SwiftUI

struct DogSexMenu: View {
    @Binding var sex: Sex?

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
        }
        label: {
            HStack {
                Text(sex.displayName)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(.rect)
        }
        .tint(.primary)
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
    DogSexMenu(sex: .constant(.female))
}
