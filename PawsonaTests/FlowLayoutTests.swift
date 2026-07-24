//
//  FlowLayoutTests.swift
//  PawsonaTests
//

import CoreGraphics
import Testing
@testable import Pawsona

@Suite("FlowLayout")
struct FlowLayoutTests {
    @Test("A run that fits on one line reports its total width and no wrap")
    func singleLine() {
        let sizes = Array(repeating: CGSize(width: 60, height: 20), count: 2)

        let result = FlowLayout.arrange(sizes: sizes, in: 500, spacing: 8)

        #expect(result.offsets[0] == CGPoint(x: 0, y: 0))
        #expect(result.offsets[1] == CGPoint(x: 68, y: 0))
        #expect(result.size == CGSize(width: 128, height: 20))
    }

    @Test("An item that would overflow the width wraps to the next line")
    func wrapsOnOverflow() {
        let sizes = Array(repeating: CGSize(width: 60, height: 20), count: 3)

        let result = FlowLayout.arrange(sizes: sizes, in: 130, spacing: 8)

        #expect(result.offsets[0] == CGPoint(x: 0, y: 0))
        #expect(result.offsets[1] == CGPoint(x: 68, y: 0))
        #expect(result.offsets[2] == CGPoint(x: 0, y: 28))
        #expect(result.size.height == 48)
    }

    @Test("A single item wider than the container still lands at the origin")
    func oversizeItemDoesNotWrapAlone() {
        let result = FlowLayout.arrange(sizes: [CGSize(width: 300, height: 40)], in: 130, spacing: 8)

        #expect(result.offsets[0] == CGPoint(x: 0, y: 0))
        #expect(result.size == CGSize(width: 300, height: 40))
    }
}
