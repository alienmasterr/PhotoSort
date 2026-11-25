//
//  SubjectMatcherTests.swift
//  PhotoSort
//
//  Created by alina on 25.11.2026.
//

import XCTest

@testable import PhotoSort

final class SubjectMatcherTests: XCTestCase {

    private let matcher = SubjectMatcher(reliableConfidenceLevel: 0.6)
    private let catLabel = VisionLabel("cat", availableLabels: ["cat"])!

    func testMatchesLabelAboveConfidenceThreshold() {
        let observations = [ClassifiedLabel(identifier: "cat", confidence: 0.8)]
        XCTAssertTrue(matcher.matches(observations, label: catLabel))
    }

    func testDoesNotMatchLabelBelowConfidenceThreshold() {
        let observations = [ClassifiedLabel(identifier: "cat", confidence: 0.4)]
        XCTAssertFalse(matcher.matches(observations, label: catLabel))
    }

    func testMatchesLabelAtConfidenceThreshold() {
        let observations = [ClassifiedLabel(identifier: "cat", confidence: 0.6)]
        XCTAssertTrue(matcher.matches(observations, label: catLabel))
    }

    func testDoesNotMatchDifferentLabel() {
        let observations = [
            ClassifiedLabel(identifier: "dog", confidence: 0.95)
        ]
        XCTAssertFalse(matcher.matches(observations, label: catLabel))
    }

    func testDoesNotMatchEmptyObservations() {
        XCTAssertFalse(matcher.matches([], label: catLabel))
    }

    func testUnknownVisionLabelReturnsNil() {
        let label = VisionLabel(
            "unicorn",
            availableLabels: ["cat", "dog"]
        )
        XCTAssertNil(label)
    }
}
