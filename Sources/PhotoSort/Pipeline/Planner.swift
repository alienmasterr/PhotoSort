//
//  Planner.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import CoreGraphics
import Foundation

struct Planner: Sendable {
    let library: PhotoLibraryProtocol
    let classifier: any ImageClassifierProtocol
    let colorAnalyzer: ColorAnalyzer
    let subjectMatcher: SubjectMatcher
    let naming: AlbumNaming
    let configuration: PhotoSorter.Configuration

    private struct SortBy: Sendable {
        let subject: Subject?
        let label: VisionLabel?
        let colors: ColorSelection?
    }

    private enum Stage: Sendable { case loading, classifying }

    private enum PhotoOutcome: Sendable {
        case matched(id: String, key: AlbumName)
        case notMatched(id: String)
        case failed(id: String, stage: Stage, error: any Error)
    }

    func plan(
        _ request: SortRequest,
        progress: (@Sendable (SortProgress) -> Void)? = nil
    ) async throws -> SortPlan {
        let isLimitedAccess = try await verifyAccess()
        let whatSortBy = try resolveSortByWhat(from: request)
        let assetIdentifiers = try await fetchIdentifiers(in: request.period)

        progress?(SortProgress(phase: .fetching, completed: 0, total: assetIdentifiers.count))

        let sum = try await scanPhotos(assetIdentifiers: assetIdentifiers, sortByWhat: whatSortBy, progress: progress)

        let albums = try buildAlbums(summary: sum, assetIdentifiers: assetIdentifiers, period: request.period)

        return SortPlan(request: request, albums: albums,
        scannedCount: sum.scannedCount,
        skippedCount: sum.failedPhotos.count, isLimitedAccess: isLimitedAccess)
    }

    private func scanPhotos(
        assetIdentifiers: [String],
        sortByWhat: SortBy,
        progress: (@Sendable (SortProgress) -> Void)?
    ) async throws -> ScanSummary {
        var summary = ScanSummary()
        var nextIndex = 0
        let maxConcurrency = configuration.maxConcurrency

        try await withThrowingTaskGroup(of: PhotoOutcome.self) { group in
            let enqueueNext:
                (inout ThrowingTaskGroup<PhotoOutcome, any Error>) -> Void = { taskGroup in
                    guard nextIndex < assetIdentifiers.count else { return }
                    let identifier = assetIdentifiers[nextIndex]
                    nextIndex += 1
                    taskGroup.addTask {
                        try await self.analyzePhoto(
                            with: identifier,
                            sortByWhat: sortByWhat
                        )
                    }
                }

            for _ in 0..<min(maxConcurrency, assetIdentifiers.count) {enqueueNext(&group)}

            var completed = 0
            while let outcome = try await group.next() {
                completed += 1
                summary.record(outcome)
                progress?(SortProgress(phase: .analyzing, completed: completed, total: assetIdentifiers.count))
                enqueueNext(&group)
            }
        }

        return summary
    }

    private func buildAlbums(
        summary: ScanSummary,
        assetIdentifiers: [String],
        period: DateInterval
    ) throws -> [SortPlan.Album] {
        if summary.scannedCount == 0,
            let error = summary.failedPhotos.lazy.compactMap({ outcome -> (any Error)? in
                if case .failed(_, .classifying, let error) = outcome { return error }
                return nil
            }).first {
            throw SortError.classificationUnavailable(underlying: error)
        }

        let photosByAlbum = Dictionary(
            grouping: summary.matchedPhotos,
            by: \.key
        )
        .mapValues { $0.map(\.id) }
        let originalOrder = Dictionary(
            uniqueKeysWithValues: assetIdentifiers.enumerated().map { ($0.element, $0.offset) }
        )

        return
            photosByAlbum
            .map { key, identifiers in
                let sortedIdentifiers = identifiers.sorted {
                    (originalOrder[$0] ?? .max) < (originalOrder[$1] ?? .max)
                }
                let title = naming.finalName(for: key, period: period)
                return SortPlan.Album(
                    title: title,
                    albumName: key,
                    assetIdentifiers: sortedIdentifiers
                )
            }
            .sorted { $0.title < $1.title }
    }

    private struct ScanSummary {
        var matchedPhotos: [(id: String, key: AlbumName)] = []
        var failedPhotos: [PhotoOutcome] = []
        var scannedCount = 0

        mutating func record(_ outcome: PhotoOutcome) {
            switch outcome {
            case .matched(let id, let key):
                matchedPhotos.append((id: id, key: key))
                scannedCount += 1
            case .notMatched:
                scannedCount += 1
            case .failed:
                failedPhotos.append(outcome)
            }
        }
    }

    private func verifyAccess() async throws -> Bool {
        switch await library.requestAccess() {
        case .full:
            return false
        case .limited:
            return true
        case .forbidden:
            throw SortError.accessDenied
        }
    }

    private func fetchIdentifiers(in period: DateInterval) async throws
        -> [String] {
        let assetIdentifiers: [String]
        do {
            assetIdentifiers = try await library.fetchAssets(in: period)
        } catch PhotoLibraryErrors.noPhotos {
            throw SortError.emptyPeriod
        } catch {
            throw SortError.libraryChangeFailed(underlying: error)
        }

        guard !assetIdentifiers.isEmpty else {
            throw SortError.emptyPeriod
        }
        return assetIdentifiers
    }

    private func buildAlbums(
        matchedPhotos: [(id: String, key: AlbumName)],
        failedPhotos: [PhotoOutcome],
        scannedCount: Int,
        assetIdentifiers: [String],
        period: DateInterval
    ) throws -> [SortPlan.Album] {
        if scannedCount == 0,
            let error = failedPhotos.lazy.compactMap({ outcome -> (any Error)? in
                if case .failed(_, .classifying, let error) = outcome {
                    return error
                }
                return nil
            }).first {
            throw SortError.classificationUnavailable(underlying: error)
        }

        let photosByAlbum = Dictionary(grouping: matchedPhotos, by: \.key)
            .mapValues { $0.map(\.id) }
        let originalOrder = Dictionary(
            uniqueKeysWithValues: assetIdentifiers.enumerated().map {
                ($0.element, $0.offset)
            }
        )

        return
            photosByAlbum
            .map { key, identifiers in
                let sortedIdentifiers = identifiers.sorted {
                    (originalOrder[$0] ?? .max) < (originalOrder[$1] ?? .max)
                }
                let title = naming.finalName(for: key, period: period)
                return SortPlan.Album(
                    title: title,
                    albumName: key,
                    assetIdentifiers: sortedIdentifiers
                )
            }
            .sorted { $0.title < $1.title }
    }

    private func resolveSortByWhat(
        from request: SortRequest
    ) throws -> SortBy {
        let colors = request.colors
        let subject = request.subject
        guard let subject else {
            return SortBy(subject: nil, label: nil, colors: colors)
        }
        let availableLabels: Set<String>
        do {
            availableLabels = try classifier.supportedLabels()
        } catch {
            throw SortError.classificationUnavailable(underlying: error)
        }
        guard
            let visionLabel = VisionLabel(
                subject.label,
                availableLabels: availableLabels
            )
        else {
            throw SortError.unknownSubjectLabel(subject.label)
        }
        return SortBy(
            subject: subject,
            label: visionLabel,
            colors: colors
        )
    }

    private func analyzePhoto(
        with identifier: String,
        sortByWhat: SortBy
    ) async throws -> PhotoOutcome {
        try Task.checkCancellation()
        let image: CGImage
        do {
            image = try await library.thumbnail(for: identifier)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return .failed(id: identifier, stage: .loading, error: error)
        }
        try Task.checkCancellation()
        var dominantColor: NamedColor?
        if let colors = sortByWhat.colors {
            guard let analysis = colorAnalyzer.analyze(image) else {
                return .notMatched(id: identifier)
            }
            guard colors.contains(analysis.color) else {
                return .notMatched(id: identifier)
            }
            dominantColor = analysis.color
        }
        if let label = sortByWhat.label {
            do {
                let observations = try await classifier.classify(image)
                try Task.checkCancellation()
                guard
                    subjectMatcher.matches(observations, label: label)
                else {
                    return .notMatched(id: identifier)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                return .failed(id: identifier, stage: .classifying, error: error)
            }
        }
        let name = AlbumName(
            colors: dominantColor.map { Set([$0]) },
            subjects: sortByWhat.subject.map { Set([$0]) }
        )
        return .matched(id: identifier, key: name)
    }
}

extension ColorSelection {
    func contains(_ color: NamedColor) -> Bool {
        switch self {
        case .all: return true
        case .only(let set): return set.contains(color)
        }
    }
}
