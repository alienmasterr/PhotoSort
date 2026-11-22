//
//  PhotoSorter.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

/// Sorts photos from the photo library into albums.
public struct PhotoSorter: Sendable {
    /// The settings used by this sorter.
    public let configuration: Configuration

    /// Creates a sorter.
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
}
