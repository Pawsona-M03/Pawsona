//
//  DogShareCardPickerView.swift
//  Pawsona
//

import SwiftUI
import UIKit

/// Shows the puppy's share card and lets the user pick the light or dark
/// version before handing it to the share sheet, rather than exporting one
/// appearance and hoping it was the one they wanted.
struct DogShareCardPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selection: ColorScheme
    @State private var cards: [ColorScheme: Data] = [:]
    @State private var sharedFile: SharedFile?

    let dog: Dog
    let dogViewModel: DogViewModel

    private static let styles: [ColorScheme] = [.light, .dark]

    init(dog: Dog, dogViewModel: DogViewModel, colorScheme: ColorScheme) {
        self.dog = dog
        self.dogViewModel = dogViewModel
        _selection = State(initialValue: colorScheme)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                preview

                styleRow

                Spacer(minLength: 0)

                Button("Share", systemImage: "square.and.arrow.up", action: share)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(cards[selection] == nil)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.appBackground))
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
        // A sheet does not inherit the tint `ContentView` puts on the tab view,
        // so the Share button and the selected thumbnail would come out system
        // blue in an app that is brown everywhere else.
        .tint(Color(.primaryBrown))
        // Both cards are rendered once, up front: the thumbnails need them
        // anyway, and re-rendering on every tap would stutter the selection.
        .task { renderCards() }
        .sheet(item: $sharedFile) { sharedFile in
            ShareSheet(fileURL: sharedFile.url, previewTitle: dog.displayName)
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let card = cards[selection], let image = UIImage(data: card) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 16))
                .accessibilityLabel("\(styleName(for: selection)) card for \(dog.displayName)")
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.cardSurface))
                .aspectRatio(DogShareCardView.width / DogShareCardView.height, contentMode: .fit)
                .overlay { ProgressView() }
                .accessibilityLabel("Preparing card")
        }
    }

    private var styleRow: some View {
        HStack(spacing: 16) {
            ForEach(Self.styles, id: \.self) { style in
                DogShareCardStyleButton(
                    card: cards[style],
                    name: styleName(for: style),
                    isSelected: selection == style
                ) {
                    selection = style
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func styleName(for colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? "Dark" : "Light"
    }

    private func renderCards() {
        for style in Self.styles where cards[style] == nil {
            cards[style] = DogShareCardRenderer.pngData(for: dog, colorScheme: style)
        }
    }

    private func share() {
        guard let card = cards[selection],
              let fileURL = dogViewModel.writeShareCard(card, for: dog) else { return }

        sharedFile = SharedFile(url: fileURL)
    }
}

/// A thumbnail of one appearance. A `Button` rather than a tappable image so it
/// carries the button trait, and `isSelected` so VoiceOver announces which of
/// the two is currently chosen.
private struct DogShareCardStyleButton: View {
    let card: Data?
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            thumbnail
                .frame(width: 132, height: 88)
                .clipShape(.rect(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(.primaryBrown) : .clear, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let card, let image = UIImage(data: card) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color(.cardSurface)
        }
    }
}

#Preview {
    DogShareCardPickerView(
        dog: Dog(
            name: "Nathan",
            breed: "Golden Retriever",
            dateOfBirth: Date(timeIntervalSinceNow: -60 * 60 * 24 * 430),
            weight: 5,
            sex: .male
        ),
        dogViewModel: DogViewModel(),
        colorScheme: .light
    )
}
