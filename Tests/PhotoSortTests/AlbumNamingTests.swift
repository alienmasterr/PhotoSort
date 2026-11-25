//
//  AlbumNamingTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class AlbumNamingTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )!
    }

    func testNameContainsColorSubjectAndYear() {
        let naming = AlbumNaming(prefix: "PhotoSort", calendar: calendar)
        let key = AlbumName(colors: [.red], subjects: [.cats])
        let period = DateInterval(
            start: date(2026, 1, 1),
            end: date(2026, 12, 31)
        )
        let name = naming.finalName(for: key, period: period)
        XCTAssertTrue(name.contains("PhotoSort"))
        XCTAssertTrue(name.contains("Red"))
        XCTAssertTrue(name.contains("Cats"))
        XCTAssertTrue(name.contains("2026"))
    }

    func testFullYearUsesYearOnly() {
        let naming = AlbumNaming(calendar: calendar)
        let key = AlbumName(colors: [.blue], subjects: nil)
        let period = DateInterval(
            start: date(2026, 1, 1),
            end: date(2026, 12, 31)
        )
        let name = naming.finalName(for: key, period: period)
        XCTAssertTrue(name.contains("2026"))
        XCTAssertFalse(name.contains("2026-01-01"))
    }

    func testPartialYearUsesDateRange() {
        let naming = AlbumNaming(calendar: calendar)
        let key = AlbumName(colors: [.green], subjects: nil)
        let period = DateInterval(
            start: date(2026, 2, 1),
            end: date(2026, 12, 31)
        )
        let name = naming.finalName(for: key, period: period)
        XCTAssertTrue(name.contains("2026-02-01"))
        XCTAssertTrue(name.contains("2026-12-31"))
    }

    func testColorNameSeparatesCamelCase() {
        let naming = AlbumNaming(calendar: calendar)
        let key = AlbumName(colors: [.yellow], subjects: nil)
        let period = DateInterval(
            start: date(2026, 1, 1),
            end: date(2026, 12, 31)
        )
        let name = naming.finalName(for: key, period: period)
        XCTAssertTrue(name.contains("Yellow"))
    }

    func testNamingIsDeterministic() {
        let naming = AlbumNaming(calendar: calendar)
        let firstKey = AlbumName(
            colors: [.red, .blue],
            subjects: [.cats, .dogs]
        )
        let secondKey = AlbumName(
            colors: [.blue, .red],
            subjects: [.dogs, .cats]
        )
        let period = DateInterval(
            start: date(2026, 1, 1),
            end: date(2026, 12, 31)
        )

        let firstName = naming.finalName(for: firstKey, period: period)
        let secondName = naming.finalName(for: secondKey, period: period)
        XCTAssertEqual(firstName, secondName)
    }

    func testDifferentKeysProduceDifferentNames() {
        let naming = AlbumNaming(calendar: calendar)
        let period = DateInterval(
            start: date(2026, 1, 1),
            end: date(2026, 12, 31)
        )

        let redKey = AlbumName(colors: [.red], subjects: nil)
        let blueKey = AlbumName(colors: [.blue], subjects: nil)
        let redName = naming.finalName(for: redKey, period: period)
        let blueName = naming.finalName(for: blueKey, period: period)
        XCTAssertNotEqual(redName, blueName)
    }
}
