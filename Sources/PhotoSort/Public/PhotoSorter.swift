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

    private let planner: Planner
    private let applier: Applier

    /// Creates a sorter.
    public init(configuration: Configuration = .default) {
        self.init(
            configuration: configuration,
            library: PhotoLibrary(),
            classifier: ImageClassifier()
        )
    }
    init(
        configuration: Configuration,
        library: any PhotoLibraryProtocol,
        classifier: any ImageClassifierProtocol
    ) {
        self.configuration = configuration
        let colorAnalyzer = ColorAnalyzer(
            minimumColorShare: configuration.minimumColorShare
        )
        let subjectMatcher = SubjectMatcher(
            reliableConfidenceLevel: configuration.minimumConfidence
        )
        let naming = AlbumNaming(prefix: configuration.albumNamePrefix)
        self.planner = Planner(
            library: library,
            classifier: classifier,
            colorAnalyzer: colorAnalyzer,
            subjectMatcher: subjectMatcher,
            naming: naming,
            configuration: configuration
        )
        self.applier = Applier(library: library)
    }

    /// Creates a sorting plan without modifying the photo library.
    ///
    /// The progress callback is not called on the main thread.
    /// Photo library access is requested internally. The host application
    /// must provide the NSPhotoLibraryUsageDescription key in its Info.plist.
    /// The operation supports cancellation.
    public func plan(
        _ request: SortRequest,
        progress: (@Sendable (SortProgress) -> Void)? = nil
    ) async throws -> SortPlan {
        try await planner.plan(request, progress: progress)
    }

    /// Applies a previously created sorting plan to the photo library.
    ///
    /// This operation is idempotent. If an error occurs, albums already
    /// created or modified remain in the library. Running the operation
    /// again adds any remaining photos without duplicating existing ones.
    public func apply(_ plan: SortPlan) async throws -> SortResult {
        try await applier.apply(plan)
    }
}
