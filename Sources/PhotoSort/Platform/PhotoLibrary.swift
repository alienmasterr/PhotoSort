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

public enum PhotoLibraryAccess {
    case full
    case limited
    case forbidden
}

public enum PhotoLibraryErrors: LocalizedError {
    case noPhotos
    case noAccess
    case albumNotCreated
    case assetNotAdded
    case albumNotFound

    public var errorDescription: String? {
        switch self {
        case .noPhotos:
            return "No photos for chosen settings have been found"
        case .noAccess:
            return
                "No access to photos. Open in settings"
        case .albumNotCreated:
            return "Can't create album"
        case .assetNotAdded:
            return "Can't add photo to album"
        case .albumNotFound:
            return "Can't find album"
        }

    }

}

public protocol PhotoLibraryProtocol {
    func requestAccess() async -> PhotoLibraryAccess
    func fetchAssets(in period: DateInterval) async throws -> [String]
    func thumbnail(for identifier: String) async throws -> CGImage
    func findAlbum(named name: String) -> String?
    func createAlbum(named name: String) async throws -> String
    func addAssets(_ identifiers: [String], to albumIdentifier: String)
        async throws
}

public struct PhotoLibrary: PhotoLibraryProtocol {

    public init() {}

    public func requestAccess() async -> PhotoLibraryAccess {
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

    public func fetchAssets(in period: DateInterval) async throws -> [String] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            period.start as NSDate,
            period.end as NSDate
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

    public func thumbnail(for identifier: String) async throws -> CGImage {
        let found = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        ).firstObject
        guard let asset = found else {
            throw PhotoLibraryErrors.noPhotos
        }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        //в цьому шматку ші допомагав
        return try await withCheckedThrowingContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 100, height: 100),
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
                    continuation.resume(throwing: PhotoLibraryErrors.noPhotos)
                    return
                }
                continuation.resume(returning: cgImage)
            }
        }

    }

    public func findAlbum(named name: String) -> String? {
        let foundAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
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

    public func createAlbum(named name: String) async throws -> String {
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

    public func addAssets(_ identifiers: [String], to albumIdentifier: String)
        async throws
    {
        guard
            let foundAlbum = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumIdentifier],
                options: nil
            ).firstObject
        else { throw PhotoLibraryErrors.albumNotFound }
        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )
        try await PHPhotoLibrary.shared().performChanges {
            let changeRequest = PHAssetCollectionChangeRequest(
                for: foundAlbum
            )

            changeRequest?.addAssets(assets)
        }

    }

}
