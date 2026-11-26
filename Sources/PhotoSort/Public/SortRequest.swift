//
//  SortRequest.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import Foundation

/// Errors of sorting process
public enum SortError: LocalizedError, Sendable {
    /// The request is not valid, for example the period is empty.
    case invalidRequest(reason: String)
    /// The app has no access to the photo library.
    case accessDenied
    /// There are no photos in the requested period.
    case emptyPeriod
    /// The subject label is not known to Vision.
    case unknownSubjectLabel(String)
    /// Photo classification failed or is not available on this device.
    case classificationUnavailable(underlying: any Error)
    /// Reading from or changing the photo library failed.
    case libraryChangeFailed(underlying: any Error)

    /// Error descriptions for user in text
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let reason):
            return reason
        case .accessDenied:
            return "No access to the photo library. Allow access in Settings."
        case .emptyPeriod:
            return "No photos were found in the requested period."
        case .unknownSubjectLabel(let label):
            return "Vision does not know the label “\(label)”."
        case .classificationUnavailable(let error):
            return "Photo classification failed: \(error.localizedDescription)"
        case .libraryChangeFailed(let error):
            return
                "The photo library operation failed: \(error.localizedDescription)"
        }
    }
}

/// Which dominant colors to create albums for.
public enum ColorSelection: Sendable, Hashable {
    /// Create an album for every dominant color that is found.
    case all
    /// Create albums only for the given colors.
    case only(Set<NamedColor>)
}

/// A request describing which photos to sort and how.
///
/// Set `subject` to keep only photos with that content, `colors` to group
/// photos into albums by dominant color, or both: for example cats where red dominates.
public struct SortRequest: Sendable {
    /// The creation-date range of photos to consider.
    public let period: DateInterval
    /// Keeps only photos that contain this subject, or `nil` for any content.
    public let subject: Subject?
    /// Groups photos by dominant color, or `nil` to not use color.
    public let colors: ColorSelection?

    /// Creates a request.
    ///
    /// - Throws: ``SortError/invalidRequest(reason:)`` if the period is empty,
    ///   neither `subject` nor `colors` is given, the color set is empty,
    ///   or the subject label is blank.
    public init(
        period: DateInterval,
        subject: Subject? = nil,
        colors: ColorSelection? = nil
    ) throws {
        guard period.duration > 0 else {
            throw SortError.invalidRequest(
                reason: "The date period must have a positive duration."
            )
        }
        guard subject != nil || colors != nil else {
            throw SortError.invalidRequest(
                reason: "Specify a subject, colors, or both."
            )
        }
        if case .only(let set)? = colors, set.isEmpty {
            throw SortError.invalidRequest(
                reason: "The color set cannot be empty."
            )
        }
        if let subject, subject.label.isEmpty {
            throw SortError.invalidRequest(
                reason: "The subject label cannot be empty."
            )
        }
        self.period = period
        self.subject = subject
        self.colors = colors
    }
}
