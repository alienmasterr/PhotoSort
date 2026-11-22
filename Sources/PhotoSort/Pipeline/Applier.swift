//
//  Applier.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import Foundation

struct Applier: Sendable {
    let library: PhotoLibraryProtocol
    func apply(_ plan: SortPlan) async throws -> SortResult {
        try Task.checkCancellation()
        guard !plan.albums.isEmpty else { return SortResult(albums: []) }
        guard await library.requestAccess() != .forbidden else {
            throw SortError.accessDenied
        }
        var results: [SortResult.Album] = []
        for album in plan.albums {
            try Task.checkCancellation()
            results.append(try await applyAlbum(album))
        }
        return SortResult(albums: results)
    }

    private func applyAlbum(_ album: SortPlan.Album) async throws
        -> SortResult.Album {
        do {
            let albumID: String
            let wasCreated: Bool
            let existing: Set<String>
            if let foundID = await library.findAlbum(named: album.title) {
                albumID = foundID
                wasCreated = false
                let ids = try await library.assetIdentifiers(inAlbum: foundID)
                existing = Set(ids)
            } else {
                albumID = try await library.createAlbum(named: album.title)
                wasCreated = true
                existing = []
            }
            let toAdd = album.assetIdentifiers.filter { !existing.contains($0) }
            if !toAdd.isEmpty {
                try await library.addAssets(toAdd, to: albumID)
            }
            return SortResult.Album(
                title: album.title,
                wasCreated: wasCreated,
                addedCount: toAdd.count,
                alreadyPresentCount: album.assetIdentifiers.count - toAdd.count
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as SortError {
            throw error
        } catch {
            throw SortError.libraryChangeFailed(underlying: error)
        }
    }
}
