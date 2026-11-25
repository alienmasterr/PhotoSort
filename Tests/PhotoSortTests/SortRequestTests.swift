//
//  SortRequestTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class SortRequestTests: XCTestCase {

    private let validPeriod = DateInterval(
        start: Date(timeIntervalSince1970: 0),
        duration: 3600
    )

    func testCreatesRequestWithSubjectOnly() throws {
        let request = try SortRequest(
            period: validPeriod,
            subject: .cats
        )
        XCTAssertEqual(request.subject, .cats)
        XCTAssertNil(request.colors)
    }

    func testCreatesRequestWithColorsOnly() throws {
        let request = try SortRequest(
            period: validPeriod,
            colors: .only([.yellow, .blue])
        )
        XCTAssertNil(request.subject)
        XCTAssertEqual(request.colors, .only([.yellow, .blue]))
    }

    func testCreatesRequestWithSubjectAndColors() throws {
        let request = try SortRequest(
            period: validPeriod,
            subject: .dogs,
            colors: .only([.green])
        )
        XCTAssertEqual(request.subject, .dogs)
        XCTAssertEqual(request.colors, .only([.green]))
    }

    func testCreatesRequestWithAllColors() throws {
        let request = try SortRequest(
            period: validPeriod,
            colors: .all
        )
        XCTAssertEqual(request.colors, .all)
    }

    func testRejectsZeroDurationPeriod() {
        let date = Date(timeIntervalSince1970: 0)
        let period = DateInterval(start: date, end: date)

        XCTAssertThrowsError(
            try SortRequest(
                period: period,
                subject: .cats
            )
        )
    }

    func testRejectsRequestWithoutSubjectOrColors() {
        XCTAssertThrowsError(
            try SortRequest(period: validPeriod)
        )
    }

    func testRejectsEmptyColorSet() {
        XCTAssertThrowsError(
            try SortRequest(
                period: validPeriod,
                colors: .only([])
            )
        )
    }

    func testRejectsEmptySubjectLabel() {
        let emptySubject = Subject(label: "")
        XCTAssertThrowsError(
            try SortRequest(
                period: validPeriod,
                subject: emptySubject
            )
        )
    }
}
