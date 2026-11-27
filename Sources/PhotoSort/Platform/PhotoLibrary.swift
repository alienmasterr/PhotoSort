//
//  PhotoLibrary.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import CoreGraphics
import Foundation
import Photos
import UIKit

enum PhotoLibraryAccess: Sendable {
    case full
    case limited
    case forbidden
}

enum PhotoLibraryErrors: LocalizedError {
    case noPhotos
    case noAccess
    case albumNotCreated
    case assetNotAdded
    case albumNotFound
    case thumbnailUnavailable

    var errorDescription: String? {
        switch self {
        case .noPhotos:
            return "No photos for chosen settings have been found"
        case .noAccess:
            return "No access to photos. Open in settings"
        case .albumNotCreated:
            return "Can't create album"
        case .assetNotAdded:
            return "Can't add photo to album"
        case .albumNotFound:
            return "Can't find album"
        case .thumbnailUnavailable:
            return "Can't get thumbnail"
        }

    }

}

protocol PhotoLibraryProtocol: Sendable {
    func requestAccess() async -> PhotoLibraryAccess
    func fetchAssets(in period: DateInterval) async throws -> [String]
    func thumbnail(for identifier: String) async throws -> CGImage
    func findAlbum(named name: String) async -> String?
    func createAlbum(named name: String) async throws -> String
    func addAssets(_ identifiers: [String], to albumIdentifier: String)
        async throws
    func assetIdentifiers(inAlbum albumIdentifier: String) async throws
        -> [String]
}

struct PhotoLibrary: PhotoLibraryProtocol, Sendable {

    // init() {}

    func requestAccess() async -> PhotoLibraryAccess {
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(
            for: .readWrite
        )
        if authorizationStatus == .authorized {
            return PhotoLibraryAccess.full
        } else if authorizationStatus == .limited {
            return PhotoLibraryAccess.limited
        }

        return PhotoLibraryAccess.forbidden

    }

    func fetchAssets(in period: DateInterval) async throws -> [String] {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: true
            )
        ]
        let datePredicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            period.start as NSDate,
            period.end as NSDate
        )
        let noScreenshotsPredicate = NSPredicate(
            format: "(mediaSubtypes & %d) == 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                datePredicate, noScreenshotsPredicate,
            ]
        )
        let assets = PHAsset.fetchAssets(with: .image, options: options)

        var localIdentifiers = [String]()
        assets.enumerateObjects { asset, _, _ in
            localIdentifiers.append(asset.localIdentifier)
        }
        if localIdentifiers.isEmpty {
            throw PhotoLibraryErrors.noPhotos
        }
        return localIdentifiers
    }

    func thumbnail(for identifier: String) async throws -> CGImage {
        let found = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        ).firstObject
        guard let asset = found else {
            throw PhotoLibraryErrors.thumbnailUnavailable
        }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return try await withCheckedThrowingContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                    isDegraded
                {
                    return
                }
                guard let cgImage = image?.cgImage else {
                    continuation.resume(
                        throwing: PhotoLibraryErrors.thumbnailUnavailable
                    )
                    return
                }
                continuation.resume(returning: cgImage)
            }
        }

    }

    func findAlbum(named name: String) -> String? {
        let foundAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )

        var foundAlbum: String?

        foundAlbums.enumerateObjects { album, _, stop in
            if album.localizedTitle == name {
                foundAlbum = album.localIdentifier
                stop.pointee = true
            }
        }
        return foundAlbum
    }

    func createAlbum(named name: String) async throws -> String {
        var albumIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let request =
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                    withTitle: name
                )

            albumIdentifier =
                request.placeholderForCreatedAssetCollection.localIdentifier
        }

        guard let albumIdentifier else {
            throw PhotoLibraryErrors.albumNotCreated
        }

        return albumIdentifier
    }

    func addAssets(_ identifiers: [String], to albumIdentifier: String)
        async throws
    {
        guard
            let foundAlbum = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumIdentifier],
                options: nil
            ).firstObject
        else { throw PhotoLibraryErrors.albumNotFound }

        let assets = PHAsset.fetchAssets(
            in: foundAlbum,
            options: nil
        )

        var nowIdentifiers = [String]()
        assets.enumerateObjects { asset, _, _ in
            nowIdentifiers.append(asset.localIdentifier)
        }
        let allIdentifiers = Array(Set(nowIdentifiers).union(identifiers))

        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: true
            )
        ]
        let sortedAssets = PHAsset.fetchAssets(
            withLocalIdentifiers: allIdentifiers,
            options: options
        )

        try await PHPhotoLibrary.shared().performChanges {
            let changeRequest = PHAssetCollectionChangeRequest(
                for: foundAlbum,
                assets: assets
            )
            changeRequest?.removeAssets(assets)

            changeRequest?.insertAssets(
                sortedAssets,
                at: IndexSet(integersIn: 0..<sortedAssets.count)
            )
        }

    }

    func assetIdentifiers(inAlbum albumIdentifier: String) async throws
        -> [String]
    {
        guard
            let album = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumIdentifier],
                options: nil
            ).firstObject
        else { throw PhotoLibraryErrors.albumNotFound }
        let assets = PHAsset.fetchAssets(in: album, options: nil)
        var identifiers = [String]()
        assets.enumerateObjects { asset, _, _ in
            identifiers.append(asset.localIdentifier)
        }
        return identifiers
    }

}
