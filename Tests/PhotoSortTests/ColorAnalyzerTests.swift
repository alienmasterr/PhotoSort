//
//  ColorAnalyzerTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class ColorAnalyzerTests: XCTestCase {

    func testSolidColorsAreRecognized() {
        let cases: [(RGB, NamedColor)] = [
            (RGB(red: 1, green: 0, blue: 0), .red),
            (RGB(red: 1, green: 0.5, blue: 0), .orange),
            (RGB(red: 1, green: 1, blue: 0), .yellow),
            (RGB(red: 0, green: 1, blue: 0), .green),
            (RGB(red: 0, green: 1, blue: 0.76), .teal),
            (RGB(red: 0, green: 0.4, blue: 1), .blue),
            (RGB(red: 0.5, green: 0, blue: 1), .purple),
            (RGB(red: 1, green: 0, blue: 0.6), .pink),
            (RGB(red: 0.5, green: 0.2, blue: 0), .brown),
            (RGB(red: 0.05, green: 0.05, blue: 0.05), .black),
            (RGB(red: 1, green: 1, blue: 1), .white),
            (RGB(red: 0.5, green: 0.5, blue: 0.5), .gray),
        ]
        let analyzer = ColorAnalyzer()
        for (rgb, expectedColor) in cases {
            let image = ImageFactory.solid(rgb)
            let result = analyzer.analyze(image)
            XCTAssertEqual(
                result?.color,
                expectedColor,
                "Expected \(expectedColor) for RGB \(rgb)"
            )
            XCTAssertEqual(result?.share ?? 0, 1, accuracy: 0.01)
        }
    }

    func testDominantColorWinsWith69PercentShare() {
        let image = ImageFactory.split(
            left: RGB(red: 1, green: 0, blue: 0),
            right: RGB(red: 0, green: 0, blue: 1),
            leftColumns: 69,
            size: 100
        )

        let result = ColorAnalyzer().analyze(image)
        XCTAssertEqual(result?.color, .red)
        XCTAssertEqual(result?.share ?? 0, 0.69, accuracy: 0.02)
    }

    func testEqualColorSharesReturnNil() {
        let image = ImageFactory.split(
            left: RGB(red: 1, green: 0, blue: 0),
            right: RGB(red: 0, green: 0, blue: 1),
            leftColumns: 32
        )
        let result = ColorAnalyzer(minimumColorShare: 0.6).analyze(image)
        XCTAssertNil(result)
    }

    func testSaturatedObjectCanWinOverGrayBackground() {
        let image = ImageFactory.split(
            left: RGB(red: 1, green: 0, blue: 0),
            right: RGB(red: 0.5, green: 0.5, blue: 0.5),
            leftColumns: 25
        )

        let result = ColorAnalyzer().analyze(image)
        XCTAssertEqual(result?.color, .red)
        XCTAssertGreaterThan(result?.share ?? 0, 0.6)
    }

    func testTransparentImageReturnsNil() {
        let image = ImageFactory.transparent()
        let result = ColorAnalyzer().analyze(image)
        XCTAssertNil(result)
    }
}
