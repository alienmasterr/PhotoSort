//
//  ApplierTests.swift
//  PhotoSort
//
//  Created by alina on 26.11.2026.
//

import XCTest

@testable import PhotoSort

final class ApplierTests: XCTestCase {

    func testCreatesAlbumAndAddsPhotos() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("cat-1", .red.asCat),
                    TestPhoto("cat-2", .red.asCat),
                ]
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1", "cat-2"]
        )
        let applier = Applier(library: library)
        let result = try await applier.apply(plan)
        XCTAssertEqual(result.albums.count, 1)
        XCTAssertEqual(result.albums[0].title, "Red Cats")
        XCTAssertTrue(result.albums[0].wasCreated)
        XCTAssertEqual(result.albums[0].addedCount, 2)
        XCTAssertEqual(result.albums[0].alreadyPresentCount, 0)
        let members = await library.members(of: "Red Cats")
        XCTAssertEqual(Set(members ?? []), ["cat-1", "cat-2"])
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 1)
    }

    func testApplyingSamePlanDoesNotAddDuplicates() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("cat-1", .red.asCat),
                    TestPhoto("cat-2", .red.asCat),
                ]
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1", "cat-2"]
        )
        let applier = Applier(library: library)
        _ = try await applier.apply(plan)
        let secondResult = try await applier.apply(plan)
        XCTAssertEqual(secondResult.albums.count, 1)
        XCTAssertFalse(secondResult.albums[0].wasCreated)
        XCTAssertEqual(secondResult.albums[0].addedCount, 0)
        XCTAssertEqual(secondResult.albums[0].alreadyPresentCount, 2)
        let members = await library.members(of: "Red Cats")
        XCTAssertEqual(members?.count, 2)
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 1)
        let addCalls = await library.addCalls
        XCTAssertEqual(addCalls, 1)
    }

    func testAddsOnlyMissingPhotosToExistingAlbum() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("cat-1", .red.asCat),
                    TestPhoto("cat-2", .red.asCat),
                ],
                albums: [
                    "Red Cats": ["cat-1"]
                ]
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1", "cat-2"]
        )
        let applier = Applier(library: library)
        let result = try await applier.apply(plan)
        XCTAssertEqual(result.albums.count, 1)
        XCTAssertFalse(result.albums[0].wasCreated)
        XCTAssertEqual(result.albums[0].addedCount, 1)
        XCTAssertEqual(result.albums[0].alreadyPresentCount, 1)
        let members = await library.members(of: "Red Cats")
        XCTAssertEqual(Set(members ?? []), ["cat-1", "cat-2"])
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 0)
        let addCalls = await library.addCalls
        XCTAssertEqual(addCalls, 1)
    }

    func testEmptyPlanDoesNotRequestLibraryAccess() async throws {
        let library = MockLibrary()
        let plan = SortPlan(
            request: try SortRequest(
                period: DateInterval(
                    start: Date(timeIntervalSince1970: 0),
                    duration: 3600
                ),
                subject: .cats
            ),
            albums: [],
            scannedCount: 0,
            skippedCount: 0,
            isLimitedAccess: false
        )
        let applier = Applier(library: library)
        let result = try await applier.apply(plan)
        XCTAssertTrue(result.albums.isEmpty)
        let accessRequests = await library.accessRequests
        XCTAssertEqual(accessRequests, 0)
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 0)
        let addCalls = await library.addCalls
        XCTAssertEqual(addCalls, 0)
    }

    func testForbiddenAccessThrowsAccessDenied() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat-1", .red.asCat)],
                access: .forbidden
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1"]
        )
        let applier = Applier(library: library)
        do {
            _ = try await applier.apply(plan)
            XCTFail("Expected SortError.accessDenied")
        } catch let error as SortError {
            guard case .accessDenied = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 0)
    }

    func testAlbumCreationFailureThrowsLibraryChangeFailed() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat-1", .red.asCat)],
                failOnCreate: true
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1"]
        )
        let applier = Applier(library: library)
        do {
            _ = try await applier.apply(plan)
            XCTFail("Expected SortError.libraryChangeFailed")
        } catch let error as SortError {
            guard case .libraryChangeFailed = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 0)
    }

    func testAddingPhotosFailureThrowsLibraryChangeFailed() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat-1", .red.asCat)],
                failOnAdd: true
            )
        )
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1"]
        )
        let applier = Applier(library: library)
        do {
            _ = try await applier.apply(plan)
            XCTFail("Expected SortError.libraryChangeFailed")
        } catch let error as SortError {
            guard case .libraryChangeFailed = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        let members = await library.members(of: "Red Cats")
        XCTAssertEqual(members, [])
        let addCalls = await library.addCalls
        XCTAssertEqual(addCalls, 0)
    }

    func testApplyThrowsCancellationErrorWhenCancelled() async throws {
        let library = MockLibrary()
        let plan = makePlan(
            title: "Red Cats",
            identifiers: ["cat-1"]
        )
        let applier = Applier(library: library)
        let task = Task { try await applier.apply(plan) }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {}
        let accessRequests = await library.accessRequests
        XCTAssertEqual(accessRequests, 0)
        let createdAlbums = await library.createdAlbums
        XCTAssertEqual(createdAlbums, 0)
    }

    private func makePlan(
        title: String,
        identifiers: [String]
    ) -> SortPlan {
        SortPlan(
            request: try! SortRequest(
                period: DateInterval(
                    start: Date(timeIntervalSince1970: 0),
                    duration: 3600
                ),
                subject: .cats
            ),
            albums: [
                SortPlan.Album(
                    title: title,
                    albumName: AlbumName(
                        colors: [.red],
                        subjects: [.cats]
                    ),
                    assetIdentifiers: identifiers
                )
            ],
            scannedCount: identifiers.count,
            skippedCount: 0,
            isLimitedAccess: false
        )
    }
}
