//
//  PhotoSorterTests.swift
//  PhotoSort
//
//  Created by alina on 26.11.2026.
//

import Foundation
import Testing
import XCTest

@testable import PhotoSort

struct PhotoSorterTests {

    @Test
    func testPlanAndApplySortPhotosIntoAlbums() async throws {
        let library = MockLibrary(
            MockLibraryConfig(photos: [
                TestPhoto("cat-1", .red.asCat), TestPhoto("cat-2", .red.asCat),
            ])
        )
        let classifier = MockClassifier()
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        let plan = try await sorter.plan(request)
        #expect(plan.albums.count == 1)
        #expect(plan.albums[0].photoCount == 2)
        let result = try await sorter.apply(plan)
        #expect(result.albums.count == 1)
        #expect(result.albums[0].wasCreated)
        #expect(result.albums[0].addedCount == 2)
        #expect(result.albums[0].alreadyPresentCount == 0)
        let members = await library.members(of: plan.albums[0].title)
        #expect(members == ["cat-1", "cat-2"])
    }

    func testApplyingSamePlanTwiceDoesNotDuplicatePhotos() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat", .red.asCat)]
            )
        )
        let classifier = MockClassifier()
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        let plan = try await sorter.plan(request)
        let firstResult = try await sorter.apply(plan)
        let secondResult = try await sorter.apply(plan)
        let title = try XCTUnwrap(plan.albums.first?.title)
        let members = await library.members(of: title)
        XCTAssertEqual(firstResult.albums.first?.addedCount, 1)
        XCTAssertEqual(secondResult.albums.first?.addedCount, 0)
        XCTAssertEqual(secondResult.albums.first?.alreadyPresentCount, 1)
        XCTAssertEqual(members, ["cat"])
    }

    func testPlanDoesNotModifyPhotoLibrary() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat", .red.asCat)]
            )
        )
        let classifier = MockClassifier()
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )

        let albumCount = await library.albumCount
        let createdAlbums = await library.createdAlbums
        let addCalls = await library.addCalls

        let plan = try await sorter.plan(request)
        XCTAssertEqual(plan.albums.count, 1)
        XCTAssertEqual(albumCount, 0)
        XCTAssertEqual(createdAlbums, 0)
        XCTAssertEqual(addCalls, 0)
    }

    func testPlanUsesConfiguredMinimumConfidence() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat", .red.asUncertainCat)]
            )
        )
        let classifier = MockClassifier()
        let configuration = PhotoSorter.Configuration(minimumConfidence: 0.2)
        let sorter = PhotoSorter(
            configuration: configuration,
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        let plan = try await sorter.plan(request)
        XCTAssertEqual(plan.albums.count, 1)
        XCTAssertEqual(plan.albums.first?.photoCount, 1)
    }

    func testPlanPropagatesClassificationUnavailable() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat", .red.asCat)]
            )
        )
        let classifier = MockClassifier(supportedError: TestError())
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        do {
            _ = try await sorter.plan(request)
            XCTFail("Expected classificationUnavailable")
        } catch let error as SortError {
            guard case .classificationUnavailable = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testApplyPropagatesLibraryChangeFailed() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("cat", .red.asCat)
                ],
                failOnCreate: true
            )
        )
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: MockClassifier()
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        let plan = try await sorter.plan(request)
        do {
            _ = try await sorter.apply(plan)
            XCTFail("Expected libraryChangeFailed")
        } catch let error as SortError {
            guard case .libraryChangeFailed = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testPlanPropagatesCancellation() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat", .red.asCat)],
                thumbnailDelay: .seconds(5)
            )
        )
        let sorter = PhotoSorter(
            configuration: .default,
            library: library,
            classifier: MockClassifier()
        )
        let request = try SortRequest(
            period: DateInterval(
                start: Date(timeIntervalSince1970: 0),
                duration: 3600
            ),
            subject: .cats
        )
        let task = Task { try await sorter.plan(request) }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
        }
    }
}
