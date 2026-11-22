//
//  Mocks.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import CoreGraphics
import Foundation

@testable import PhotoSort

struct TestError: Error, Sendable {}

final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }

    var current: Value { withValue { $0 } }
}

struct TestPhoto: Sendable {
    let identifier: String
    let image: TestImage

    init(_ identifier: String, _ image: TestImage) {
        self.identifier = identifier
        self.image = image
    }
}

struct MockLibraryConfig: Sendable {
    var photos: [TestPhoto] = []
    var access: PhotoLibraryAccess = .full
    var fetchError: (any Error)?
    var failingThumbnails: Set<String> = []
    var thumbnailDelay: Duration?
    var failOnCreate = false
    var failOnAdd = false
    var albums: [String: [String]] = [:]
}

actor MockLibrary: PhotoLibraryProtocol {
    private struct Album {
        let identifier: String
        var members: [String]
    }

    private let config: MockLibraryConfig
    private var albums: [String: Album] = [:]
    private var inFlight = 0

    private(set) var accessRequests = 0
    private(set) var thumbnailRequests = 0
    private(set) var createdAlbums = 0
    private(set) var addCalls = 0
    private(set) var maxInFlight = 0

    init(_ config: MockLibraryConfig = MockLibraryConfig()) {
        self.config = config
        for (title, members) in config.albums {
            albums[title] = Album(
                identifier: "album-\(title)",
                members: members
            )
        }
    }

    func members(of title: String) -> [String]? {
        albums[title]?.members
    }

    var albumCount: Int { albums.count }

    func requestAccess() async -> PhotoLibraryAccess {
        accessRequests += 1
        return config.access
    }

    func fetchAssets(in period: DateInterval) async throws -> [String] {
        if let fetchError = config.fetchError { throw fetchError }
        if config.photos.isEmpty { throw PhotoLibraryErrors.noPhotos }
        return config.photos.map(\.identifier)
    }

    func thumbnail(for identifier: String) async throws -> CGImage {
        thumbnailRequests += 1
        inFlight += 1
        maxInFlight = max(maxInFlight, inFlight)
        defer { inFlight -= 1 }

        if let delay = config.thumbnailDelay {
            try await Task.sleep(for: delay)
        }
        if config.failingThumbnails.contains(identifier) {
            throw PhotoLibraryErrors.thumbnailUnavailable
        }
        guard
            let photo = config.photos.first(where: {
                $0.identifier == identifier
            })
        else {
            throw PhotoLibraryErrors.thumbnailUnavailable
        }
        return photo.image.makeCGImage()
    }

    func findAlbum(named name: String) async -> String? {
        albums[name]?.identifier
    }

    func createAlbum(named name: String) async throws -> String {
        if config.failOnCreate { throw PhotoLibraryErrors.albumNotCreated }
        createdAlbums += 1
        let identifier = "album-\(name)"
        albums[name] = Album(identifier: identifier, members: [])
        return identifier
    }

    func assetIdentifiers(inAlbum albumIdentifier: String) async throws
        -> [String]
    {
        guard
            let album = albums.values.first(where: {
                $0.identifier == albumIdentifier
            })
        else {
            throw PhotoLibraryErrors.albumNotFound
        }
        return album.members
    }

    func addAssets(_ identifiers: [String], to albumIdentifier: String)
        async throws
    {
        if config.failOnAdd { throw PhotoLibraryErrors.assetNotAdded }
        guard
            let entry = albums.first(where: {
                $0.value.identifier == albumIdentifier
            })
        else {
            throw PhotoLibraryErrors.albumNotFound
        }
        addCalls += 1
        albums[entry.key]?.members.append(contentsOf: identifiers)
    }
}

struct MockClassifier: ImageClassifierProtocol, Sendable {
    var supported: Set<String> = ["cat", "dog", "sky"]
    var supportedError: (any Error)?
    var classifyError: (any Error)?
    var failingWidth: Int?
    let calls = LockedBox(0)

    func supportedLabels() throws -> Set<String> {
        if let supportedError { throw supportedError }
        return supported
    }

    func classify(_ image: CGImage) async throws -> [ClassifiedLabel] {
        calls.withValue { $0 += 1 }
        if let classifyError { throw classifyError }
        if image.width == failingWidth { throw TestError() }
        switch image.width {
        case TestImage.catWidth:
            return [ClassifiedLabel(identifier: "cat", confidence: 0.95)]
        case TestImage.uncertainCatWidth:
            return [ClassifiedLabel(identifier: "cat", confidence: 0.3)]
        default:
            return [ClassifiedLabel(identifier: "sky", confidence: 0.9)]
        }
    }
}
