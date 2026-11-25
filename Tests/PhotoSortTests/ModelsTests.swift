//
//  ModelsTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class ModelsTests: XCTestCase {

    func testConfigurationClampsMaxConcurrencyToAtLeastOne() {
        let configuration = PhotoSorter.Configuration(maxConcurrency: 0)
        XCTAssertEqual(configuration.maxConcurrency, 1)
    }

    func testConfigurationClampsConfidenceToValidRange() {
        let tooLow = PhotoSorter.Configuration(minimumConfidence: -0.5)
        let tooHigh = PhotoSorter.Configuration(minimumConfidence: 1.5)
        XCTAssertEqual(tooLow.minimumConfidence, 0)
        XCTAssertEqual(tooHigh.minimumConfidence, 1)
    }

    func testConfigurationClampsColorShareToValidRange() {
        let tooLow = PhotoSorter.Configuration(minimumColorShare: -0.5)
        let tooHigh = PhotoSorter.Configuration(minimumColorShare: 1.5)
        XCTAssertEqual(tooLow.minimumColorShare, 0)
        XCTAssertEqual(tooHigh.minimumColorShare, 1)
    }

    func testDefaultConfigurationHasExpectedValues() {
        let configuration = PhotoSorter.Configuration.default
        XCTAssertEqual(configuration.maxConcurrency, 4)
        XCTAssertEqual(configuration.minimumConfidence, 0.6)
        XCTAssertEqual(configuration.minimumColorShare, 0.6)
    }

    func testProgressFraction() {
        let progress = SortProgress(
            phase: .analyzing,
            completed: 3,
            total: 10
        )
        XCTAssertEqual(progress.fraction, 0.3, accuracy: 0.001)
    }

    func testProgressFractionIsZeroWhenTotalIsZero() {
        let progress = SortProgress(
            phase: .fetching,
            completed: 0,
            total: 0
        )
        XCTAssertEqual(progress.fraction, 0)
    }

    func testResultCountsCreatedAlbumsAndAddedPhotos() {
        let result = SortResult(
            albums: [
                SortResult.Album(
                    title: "Cats",
                    wasCreated: true,
                    addedCount: 5,
                    alreadyPresentCount: 0
                ),
                SortResult.Album(
                    title: "Dogs",
                    wasCreated: false,
                    addedCount: 3,
                    alreadyPresentCount: 2
                ),
                SortResult.Album(
                    title: "Red",
                    wasCreated: true,
                    addedCount: 2,
                    alreadyPresentCount: 1
                ),
            ]
        )

        XCTAssertEqual(result.createdAlbumCount, 2)
        XCTAssertEqual(result.addedPhotoCount, 10)
    }

    func testEmptyResultHasZeroCounts() {
        let result = SortResult(albums: [])
        XCTAssertEqual(result.createdAlbumCount, 0)
        XCTAssertEqual(result.addedPhotoCount, 0)
    }
}
