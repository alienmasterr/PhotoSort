//
//  SubjectMatcher.swift
//  PhotoSort
//
//  Created by alina on 21.11.2026.
//

import Vision

struct VisionLabel: Hashable, Sendable {
    let name: String

    init?(_ name: String, availableLabels: Set<String>) {
        guard availableLabels.contains(name) else {
            return nil
        }
        self.name = name
    }
}

struct SubjectMatcher {

    private let reliableConfidenceLevel: Float

    init(
        reliableConfidenceLevel: Float = 0.60
    ) {
        self.reliableConfidenceLevel = reliableConfidenceLevel
    }

    func matches(
        _ observations: [VNClassificationObservation],
        label: VisionLabel
    ) -> Bool {
        observations.contains {
            $0.identifier == label.name
                && $0.confidence >= reliableConfidenceLevel
        }

    }
}
