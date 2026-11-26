//
//  Configuration.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

/// Eddition to PhotoSorter
extension PhotoSorter {
    /// Settings that tune how photos are analyzed.
    public struct Configuration: Sendable {
        /// How many photos are analyzed at the same time. Minimum 1.
        public let maxConcurrency: Int
        /// The minimum Vision confidence, from 0 to 1, to accept a subject.
        public let minimumConfidence: Float
        /// The minimum share, from 0 to 1, a color must cover to count as dominant.
        public let minimumColorShare: Double
        /// The prefix of album titles.
        public let albumNamePrefix: String

        /// Creates a configuration.
        public init(
            maxConcurrency: Int = 4,
            minimumConfidence: Float = 0.6,
            minimumColorShare: Double = 0.6,
            albumNamePrefix: String = "PhotoSort"
        ) {
            self.maxConcurrency = max(1, maxConcurrency)
            self.minimumConfidence = min(max(minimumConfidence, 0), 1)
            self.minimumColorShare = min(max(minimumColorShare, 0), 1)
            self.albumNamePrefix = albumNamePrefix
        }

        /// The default settings.
        public static let `default` = Configuration()
    }
}
