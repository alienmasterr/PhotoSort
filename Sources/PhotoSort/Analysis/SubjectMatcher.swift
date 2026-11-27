//
//  SubjectMatcher.swift
//  PhotoSort
//
//  Created by alina on 21.11.2026.
//

struct VisionLabel: Hashable, Sendable {
    /// The recognized label name.
    public let name: String

    init?(_ name: String, availableLabels: Set<String>) {
        guard availableLabels.contains(name) else {
            return nil
        }
        self.name = name
    }
}

struct SubjectMatcher: Sendable {

    private let reliableConfidenceLevel: Float

    init(
        reliableConfidenceLevel: Float = 0.60
    ) {
        self.reliableConfidenceLevel = reliableConfidenceLevel
    }

    func matches(
        _ observations: [ClassifiedLabel],
        label: VisionLabel
    ) -> Bool {
        observations.contains {
            $0.identifier == label.name
                && $0.confidence >= reliableConfidenceLevel
        }

    }
}
