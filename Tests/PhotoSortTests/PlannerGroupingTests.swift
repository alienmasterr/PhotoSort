//
//  PlannerGroupingTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class PlannerGroupingTests: XCTestCase {

    private let period = DateInterval(
        start: Date(timeIntervalSince1970: 0),
        duration: 3600
    )

    private func makePlanner(photos: [TestPhoto]) -> Planner {
        Planner(
            library: MockLibrary(MockLibraryConfig(photos: photos)),
            classifier: MockClassifier(),
            colorAnalyzer: ColorAnalyzer(),
            subjectMatcher: SubjectMatcher(reliableConfidenceLevel: 0.6),
            naming: AlbumNaming(),
            configuration: .default
        )
    }

    func testAllColorsCreateSeparateAlbums() async throws {
        let photos = [
            TestPhoto("red-photo", .red), TestPhoto("green-photo", .green),
            TestPhoto("blue-photo", .blue),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            colors: .all
        )
        let plan = try await planner.plan(request)
        XCTAssertEqual(plan.albums.count, 3)
        XCTAssertEqual(
            Set(plan.albums.compactMap { $0.albumName.colors?.first }),
            [.red, .green, .blue]
        )
    }

    func testOnlySelectedColorsAreIncluded() async throws {
        let photos = [
            TestPhoto("red-photo", .red),
            TestPhoto("green-photo", .green),
            TestPhoto("blue-photo", .blue),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            colors: .only([.red, .blue])
        )
        let plan = try await planner.plan(request)
        XCTAssertEqual(plan.albums.count, 2)
        let identifiers = Set(plan.albums.flatMap(\.assetIdentifiers))
        XCTAssertEqual(identifiers, ["red-photo", "blue-photo"])
    }

    func testSubjectAndColorMustBothMatch() async throws {
        let photos = [
            TestPhoto("red-cat", .red.asCat),
            TestPhoto("blue-cat", .blue.asCat),
            TestPhoto("red-other", .red),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            subject: .cats,
            colors: .only([.red])
        )
        let plan = try await planner.plan(request)
        XCTAssertEqual(plan.albums.count, 1)
        XCTAssertEqual(
            plan.albums.first?.albumName,
            AlbumName(colors: [.red], subjects: [.cats])
        )
        XCTAssertEqual(
            plan.albums.first?.assetIdentifiers,
            ["red-cat"]
        )
    }

    func testSubjectWithAllColorsCreatesSeparateAlbums() async throws {
        let photos = [
            TestPhoto("red-cat", .red.asCat),
            TestPhoto("blue-cat", .blue.asCat),
            TestPhoto("green-other", .green),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            subject: .cats,
            colors: .all
        )
        let plan = try await planner.plan(request)
        XCTAssertEqual(plan.albums.count, 2)
        let identifiers = Set(plan.albums.flatMap(\.assetIdentifiers))
        XCTAssertEqual(identifiers, ["red-cat", "blue-cat"])
        for album in plan.albums {
            XCTAssertEqual(album.albumName.subjects, [.cats])
        }
    }

    func testSubjectOnlyCreatesOneAlbum() async throws {
        let photos = [
            TestPhoto("first-cat", .red.asCat),
            TestPhoto("second-cat", .blue.asCat),
            TestPhoto("not-cat", .green),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        let plan = try await planner.plan(request)
        XCTAssertEqual(plan.albums.count, 1)
        XCTAssertEqual(
            plan.albums.first?.albumName,
            AlbumName(colors: nil, subjects: [.cats])
        )
        XCTAssertEqual(
            Set(plan.albums.first?.assetIdentifiers ?? []),
            ["first-cat", "second-cat"]
        )
    }

    func testNoMatchesReturnsEmptyPlan() async throws {
        let photos = [
            TestPhoto("red-photo", .red),
            TestPhoto("blue-photo", .blue),
        ]
        let planner = makePlanner(photos: photos)
        let request = try SortRequest(
            period: period,
            colors: .only([.purple])
        )
        let plan = try await planner.plan(request)
        XCTAssertTrue(plan.albums.isEmpty)
    }
}
