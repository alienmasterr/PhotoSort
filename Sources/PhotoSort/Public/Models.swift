//
//  Models.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

/// A preview of the albums that ``PhotoSorter/apply(_:)`` would create or update.
public struct SortPlan: Sendable {
    /// One album in the plan.
    public struct Album: Sendable {
        /// The album title.
        public let title: String
        /// The number of photos that would be placed in the album.
        public var photoCount: Int { assetIdentifiers.count }

        let albumName: AlbumName
        
        /// The identifiers of photos assigned to this album.
        public let assetIdentifiers: [String]
    }

    /// The request this plan was made for.
    public let request: SortRequest
    /// The albums to create or update, sorted by title.
    public let albums: [Album]
    /// How many photos were analyzed successfully.
    public let scannedCount: Int
    /// How many photos could not be analyzed, for example iCloud photos that are not on the device.
    public let skippedCount: Int
    /// `true` if the user allowed access only to selected photos.
    public let isLimitedAccess: Bool
}

/// The outcome of ``PhotoSorter/apply(_:)``.
public struct SortResult: Sendable {
    /// What happened to one album.
    public struct Album: Sendable {
        /// The album title.
        public let title: String
        /// `true` if the album was created, `false` if it already existed.
        public let wasCreated: Bool
        /// How many photos were added.
        public let addedCount: Int
        /// How many photos were already in the album.
        public let alreadyPresentCount: Int
    }

    /// Results per album.
    public let albums: [Album]
    /// The number of albums that were created.
    public var createdAlbumCount: Int { albums.filter(\.wasCreated).count }
    /// The total number of photos that were added.
    public var addedPhotoCount: Int { albums.reduce(0) { $0 + $1.addedCount } }
}

/// A progress report delivered while ``PhotoSorter/plan(_:progress:)`` runs.
public struct SortProgress: Sendable {
    /// The stage of planning.
    public enum Phase: Sendable {
        /// Finding photos in the library.
        case fetching
        /// Analyzing photos.
        case analyzing
    }

    /// The current stage.
    public let phase: Phase
    /// How many photos are processed.
    public let completed: Int
    /// How many photos there are in total.
    public let total: Int
    /// Progress from 0 to 1.
    public var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}
