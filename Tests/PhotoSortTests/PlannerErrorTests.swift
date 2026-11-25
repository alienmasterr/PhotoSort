//
//  PlannerErrorTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class PlannerErrorTests: XCTestCase {

    private let period = DateInterval(
        start: Date(timeIntervalSince1970: 0),
        duration: 3600
    )

    private func makePlanner(
        library: MockLibrary,
        classifier: MockClassifier = MockClassifier()
    ) -> Planner {
        Planner(
            library: library,
            classifier: classifier,
            colorAnalyzer: ColorAnalyzer(),
            subjectMatcher: SubjectMatcher(
                reliableConfidenceLevel: 0.6
            ),
            naming: AlbumNaming(),
            configuration: .default
        )
    }

    func testForbiddenAccessThrowsAccessDenied() async {
        let library = MockLibrary(MockLibraryConfig(access: .forbidden))
        let planner = makePlanner(library: library)
        let request = try! SortRequest(
            period: period,
            colors: .all
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected accessDenied error")
        } catch let error as SortError {
            guard case .accessDenied = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLimitedAccessIsReflectedInPlan() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("red-photo", .red)],
                access: .limited
            )
        )
        let planner = makePlanner(library: library)
        let request = try SortRequest(
            period: period,
            colors: .all
        )
        let plan = try await planner.plan(request)
        XCTAssertTrue(plan.isLimitedAccess)
    }

    func testEmptyLibraryThrowsEmptyPeriod() async {
        let library = MockLibrary()
        let planner = makePlanner(library: library)
        let request = try! SortRequest(
            period: period,
            colors: .all
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected emptyPeriod error")
        } catch let error as SortError {
            guard case .emptyPeriod = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLibraryFailureThrowsLibraryChangeFailed() async {
        let library = MockLibrary(
            MockLibraryConfig(fetchError: TestError())
        )
        let planner = makePlanner(library: library)

        let request = try! SortRequest(
            period: period,
            colors: .all
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected libraryChangeFailed error")
        } catch let error as SortError {
            guard case .libraryChangeFailed = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnknownSubjectLabelDoesNotLoadThumbnails() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("red-photo", .red)]
            )
        )
        let planner = makePlanner(library: library)
        let request = try SortRequest(
            period: period,
            subject: Subject(label: "unicorn")
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected unknownSubjectLabel error")
        } catch let error as SortError {
            guard case .unknownSubjectLabel = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let thumbnailRequests = await library.thumbnailRequests
        XCTAssertEqual(thumbnailRequests, 0)
    }

    func testSupportedLabelsFailureThrowsClassificationUnavailable() async {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [TestPhoto("cat-photo", .red.asCat)]
            )
        )
        let classifier = MockClassifier(
            supportedError: TestError()
        )
        let planner = makePlanner(
            library: library,
            classifier: classifier
        )
        let request = try! SortRequest(
            period: period,
            subject: .cats
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected classificationUnavailable error")
        } catch let error as SortError {
            guard case .classificationUnavailable(underlying: _) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let thumbnailRequests = await library.thumbnailRequests
        XCTAssertEqual(thumbnailRequests, 0)
    }

    func testAllClassificationFailuresThrowClassificationUnavailable() async {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("first-cat", .red.asCat),
                    TestPhoto("second-cat", .blue.asCat),
                ]
            )
        )
        let classifier = MockClassifier(
            classifyError: TestError()
        )
        let planner = makePlanner(
            library: library,
            classifier: classifier
        )
        let request = try! SortRequest(
            period: period,
            subject: .cats
        )
        do {
            _ = try await planner.plan(request)
            XCTFail("Expected classificationUnavailable error")
        } catch let error as SortError {
            guard case .classificationUnavailable(underlying: _) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPartialClassificationFailureStillReturnsPlan() async throws {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("failed-cat", .red.asCat),
                    TestPhoto("successful-cat", .blue.asCat),
                ]
            )
        )
        let classifier = MockClassifier(
            failFirstCall: true
        )
        let planner = makePlanner(
            library: library,
            classifier: classifier
        )
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        let plan = try await planner.plan(request)
        let identifiers = Set(plan.albums.flatMap(\.assetIdentifiers))
        XCTAssertEqual(identifiers.count, 1)
        XCTAssertTrue(
            identifiers.isSubset(of: ["failed-cat", "successful-cat"])
        )
    }

    func testAllThumbnailFailuresDoNotThrowClassificationUnavailable()
        async throws
    {
        let library = MockLibrary(
            MockLibraryConfig(
                photos: [
                    TestPhoto("first-cat", .red.asCat),
                    TestPhoto("second-cat", .blue.asCat),
                ],
                failingThumbnails: ["first-cat", "second-cat"]
            )
        )
        let planner = makePlanner(library: library)
        let request = try SortRequest(
            period: period,
            subject: .cats
        )
        let plan = try await planner.plan(request)
        XCTAssertTrue(plan.albums.isEmpty)
    }
}
