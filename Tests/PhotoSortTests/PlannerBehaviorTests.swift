//
//  PlannerBehaviorTests.swift
//  PhotoSort
//
//  Created by alina on 26.11.2026.
//

import XCTest

@testable import PhotoSort

final class PlannerBehaviorTests: XCTestCase {

    private let period = DateInterval(
        start: Date(timeIntervalSince1970: 0),
        duration: 3600
    )

    func testClassifierIsNotCalledWhenColorDoesNotMatch() async throws {
        let library = MockLibrary(
            MockLibraryConfig(photos: [TestPhoto("blue-photo", .blue)])
        )
        let classifier = MockClassifier()
        let planner = makePlanner(
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: period,
            subject: .cats,
            colors: .only([.red])
        )
        _ = try await planner.plan(request)
        XCTAssertEqual(classifier.calls.current, 0)
    }

    func testPlanIsSameWithDifferentConcurrencyLimits() async throws {
        let photos = [
            TestPhoto("red-cat", .red.asCat),
            TestPhoto("blue-cat", .blue.asCat),
            TestPhoto("green-cat", .green.asCat),
        ]
        let serialLibrary = MockLibrary(MockLibraryConfig(photos: photos))
        let concurrentLibrary = MockLibrary(MockLibraryConfig(photos: photos))
        let serialPlanner = makePlanner(
            library: serialLibrary,
            maxConcurrency: 1
        )
        let concurrentPlanner = makePlanner(
            library: concurrentLibrary,
            maxConcurrency: 4
        )
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        let serialPlan = try await serialPlanner.plan(request)
        let concurrentPlan = try await concurrentPlanner.plan(request)
        XCTAssertEqual(serialPlan.scannedCount, concurrentPlan.scannedCount)
        XCTAssertEqual(serialPlan.skippedCount, concurrentPlan.skippedCount)
        XCTAssertEqual(serialPlan.albums.count, concurrentPlan.albums.count)
        let serialAlbums = Dictionary(
            uniqueKeysWithValues: serialPlan.albums.map {
                ($0.title, Set($0.assetIdentifiers))
            }
        )
        let concurrentAlbums = Dictionary(
            uniqueKeysWithValues: concurrentPlan.albums.map {
                ($0.title, Set($0.assetIdentifiers))
            }
        )
        XCTAssertEqual(serialAlbums, concurrentAlbums)
    }

    func testMaximumConcurrencyDoesNotExceedLimit() async throws {
        let photos = (0..<10).map { TestPhoto("cat-\($0)", .red.asCat) }
        let library = MockLibrary(
            MockLibraryConfig(
                photos: photos,
                thumbnailDelay: .milliseconds(20)
            )
        )
        let planner = makePlanner(
            library: library,
            maxConcurrency: 3
        )
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        _ = try await planner.plan(request)
        let maxInFlight = await library.maxInFlight
        XCTAssertLessThanOrEqual(maxInFlight, 3)
        XCTAssertGreaterThan(maxInFlight, 1)
    }

    func testProgressReachesTotal() async throws {
        let photos = (0..<5).map { TestPhoto("cat-\($0)", .red.asCat) }
        let library = MockLibrary(MockLibraryConfig(photos: photos))
        let planner = makePlanner(library: library)
        let progressUpdates = LockedBox<[SortProgress]>([])
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        _ = try await planner.plan(request) { progress in
            progressUpdates.withValue { $0.append(progress) }
        }
        let updates = progressUpdates.current
        let analyzingUpdates = updates.filter { $0.phase == .analyzing }
        XCTAssertFalse(analyzingUpdates.isEmpty)
        XCTAssertEqual(analyzingUpdates.last?.completed, photos.count)
        XCTAssertEqual(analyzingUpdates.last?.total, photos.count)
        for update in analyzingUpdates {
            XCTAssertLessThanOrEqual(update.completed, update.total)
        }
    }

    func testPlanningDoesNotModifyPhotoLibrary() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("red-cat", .red.asCat),
                    TestPhoto("blue-cat", .blue.asCat),
                ]
            )
        )
        let planner = makePlanner(library: library)
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        _ = try await planner.plan(request)
        let albumCount = await library.albumCount
        let createdAlbums = await library.createdAlbums
        let addCalls = await library.addCalls
        XCTAssertEqual(albumCount, 0)
        XCTAssertEqual(createdAlbums, 0)
        XCTAssertEqual(addCalls, 0)
    }

    func testPlanningThrowsCancellationErrorWhenCancelled() async throws {
        let photos = (0..<10).map { TestPhoto("cat-\($0)", .red.asCat) }
        let library = MockLibrary(
            MockLibraryConfig(
                photos: photos,
                thumbnailDelay: .seconds(2)
            )
        )
        let planner = makePlanner(
            library: library,
            maxConcurrency: 1
        )
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        let task = Task { try await planner.plan(request) }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {

        }
    }

    private func makePlanner(
        library: MockLibrary,
        classifier: MockClassifier = MockClassifier(),
        maxConcurrency: Int = 4
    ) -> Planner {
        Planner(
            library: library,
            classifier: classifier,
            colorAnalyzer: ColorAnalyzer(),
            subjectMatcher: SubjectMatcher(reliableConfidenceLevel: 0.6),
            naming: AlbumNaming(),
            configuration: .init(
                maxConcurrency: maxConcurrency,
                minimumConfidence: 0.6,
                minimumColorShare: 0.6
            )
        )
    }
}
