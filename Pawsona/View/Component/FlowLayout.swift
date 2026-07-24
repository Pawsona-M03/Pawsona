//
//  FlowLayout.swift
//  Pawsona
//

import SwiftUI

/// A left-to-right layout that wraps its subviews onto new lines when the next
/// one would overflow the available width — used for the linked-dog avatar
/// clusters on the reminder and vaccine cards, so a record with many dogs grows
/// taller instead of pushing the card wider than the screen.
///
/// The wrapping maths lives in the pure, static `arrange(sizes:in:spacing:)` so
/// it can be unit-tested without constructing SwiftUI's `Subviews`.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return Self.arrange(sizes: sizes, in: proposal.width ?? .infinity, spacing: spacing).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = Self.arrange(sizes: sizes, in: bounds.width, spacing: spacing).offsets

        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + offsets[index].x, y: bounds.minY + offsets[index].y),
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }

    /// Places each size in reading order, wrapping to a new line before any item
    /// (other than a line's first) that would exceed `maxWidth`. Returns each
    /// item's top-left offset and the total size the run occupies.
    static func arrange(
        sizes: [CGSize],
        in maxWidth: CGFloat,
        spacing: CGFloat
    ) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for size in sizes {
            if cursorX > 0, cursorX + size.width > maxWidth {
                cursorY += lineHeight + spacing
                cursorX = 0
                lineHeight = 0
            }

            offsets.append(CGPoint(x: cursorX, y: cursorY))
            cursorX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widestLine = max(widestLine, cursorX - spacing)
        }

        return (CGSize(width: widestLine, height: cursorY + lineHeight), offsets)
    }
}
