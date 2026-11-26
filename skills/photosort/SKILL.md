---
name: photosort
description: PhotoSort sorts an iOS photo library into albums by dominant color or recognized subject. Use when an iOS app imports PhotoSort and needs to configure, integrate, or use its photo sorting API.
license: MIT
metadata:
  version: "1.0.0"
---

# PhotoSort Skill
Use this skill when integrating or working with the PhotoSort framework in an iOS application.
PhotoSort analyzes photos and creates albums based on dominant colors, recognized subjects, or both.
## Requirements
- iOS 16.0 or later.
- Swift 6.0.
- Xcode 16.0 or later.
- Photo library access permission.
- PhotoSort does not support macOS.

## Installation
Add PhotoSort to the application using Swift Package Manager.
In Xcode:
1. Select **File → Add Package Dependencies**.
2. Enter the PhotoSort repository URL.
3. Select a version starting from `1.0.0`.
4. Add the `PhotoSort` product to the application target.

Alternatively, add it to `Package.swift`:
```swift
.package(
    url: "https://github.com/alienmasterr/PhotoSort",
    from: "1.0.0"
)
```
Add the `PhotoSort` product to the target dependencies.

## Photo Library Permission
The host application must provide `NSPhotoLibraryUsageDescription` in its `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoSort needs access to your photo library to analyze and organize your photos into albums.</string>
```
PhotoSort requests photo library access when `plan` or `apply` is called. The application is responsible for providing the usage description.

## Public API
Import the framework:
```swift
import PhotoSort
```

### PhotoSorter
`PhotoSorter` is the main entry point.
```swift
let sorter = PhotoSorter()
```

It exposes two asynchronous operations:
- `plan(_:progress:)` analyzes photos and creates a `SortPlan` without modifying the library.
- `apply(_:)` applies a previously created plan and returns a `SortResult`.

### SortRequest
`SortRequest` defines the period and sorting criteria.
```swift
let request = try SortRequest(
    period: period,
    subject: .cats,
    colors: .only([.red, .blue])
)
```
The request can use a subject, colors, or both. At least one sorting criterion must be provided.
The period must be a valid, non-empty `DateInterval`.

### ColorSelection and NamedColor
Use `ColorSelection.all` to include all supported colors:
```swift
let request = try SortRequest(
    period: period,
    colors: .all
)
```

Use `ColorSelection.only(_:)` to select specific colors:
```swift
let request = try SortRequest(
    period: period,
    colors: .only([.red, .green, .blue])
)
```
Supported colors are:
`red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink`, `brown`, `black`, `white`, and `gray`.

### Subject
PhotoSort provides predefined subjects:
```swift
Subject.cats
Subject.dogs
```
A custom subject can be created:
```swift
let subject = Subject(label: "bird")
```
The label must be supported by the underlying Vision classifier. Creating a `Subject` does not register a new classification label.

### SortPlan
`SortPlan` describes the proposed changes.
Its public properties include:
- `request` — the original sorting request.
- `albums` — the albums proposed by the planner.
- `scannedCount` — the number of photos scanned.
- `skippedCount` — the number of photos skipped.
- `isLimitedAccess` — whether photo library access was limited.

Each `SortPlan.Album` exposes:
- `title` — the proposed album title.
- `photoCount` — the number of photos assigned to the album.
- `assetIdentifiers` — the identifiers of the assigned photos.

### SortResult
`SortResult` describes the changes made by `apply(_:)`.
Each `SortResult.Album` provides:
- `title` — the album title.
- `wasCreated` — whether the album was created.
- `addedCount` — the number of photos added.
- `alreadyPresentCount` — the number of photos that were already in the album.
The result also provides `createdAlbumCount` and `addedPhotoCount`.

### SortProgress
Pass a progress closure to `plan` to receive updates:
```swift
let plan = try await sorter.plan(request) { progress in
    print(
        "\(progress.phase): \(progress.completed)/\(progress.total)"
    )
}
```

`SortProgress` provides:
- `phase` — the current phase (`fetching` or `analyzing`).
- `completed` — the number of completed items.
- `total` — the total number of items.
- `fraction` — the completion fraction from `0.0` to `1.0`.
The progress callback is not called on the main thread. Dispatch UI updates to the main actor when necessary.

### SortError
PhotoSort reports errors using `SortError`:
- `invalidRequest(reason:)` — the request is invalid.
- `accessDenied` — photo library access was denied.
- `emptyPeriod` — no photos were found in the requested period.
- `unknownSubjectLabel(_:)` — the requested subject label is not supported.
- `classificationUnavailable(underlying:)` — classification could not be performed.
- `libraryChangeFailed(underlying:)` — a photo library operation failed.

Handle errors with `do` / `catch`:
```swift
do {
    let plan = try await sorter.plan(request)
    let result = try await sorter.apply(plan)
    print("Added \(result.addedPhotoCount) photos")
} catch let error as SortError {
    print("PhotoSort error: \(error.localizedDescription)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Recommended Workflow
Always use the two-step workflow:
1. Create a `SortRequest` with a specific date interval and at least one sorting criterion.
2. Call `plan` to analyze photos and generate a `SortPlan`.
3. Inspect the proposed albums if needed.
4. Call `apply` to modify the photo library.
```swift
let plan = try await sorter.plan(request)

for album in plan.albums {
    print("\(album.title): \(album.photoCount)")
}

let result = try await sorter.apply(plan)
```
`plan` is a dry-run operation and does not modify the photo library.
`apply` is idempotent: it checks existing album contents and adds only missing photos. If an operation fails after some changes have been made, those changes are not rolled back. Applying the same plan again can add the remaining photos without duplicating existing ones.

## Common Mistakes
- Do not create a request without a sorting criterion.
- Do not use an empty or invalid date interval.
- Do not assume that an arbitrary `Subject` label is supported by Vision.
- Do not call `apply` when you only want to preview the proposed changes.
- Do not assume that limited photo library access includes every photo in the library.
- Do not update UI directly from the progress callback; it is not called on the main thread.
- Do not assume that applying a plan is transactional. Previously completed library changes remain if a later operation fails.

## API Boundaries
The following APIs and capabilities do not exist in PhotoSort:
- `PhotoSorter.shared` — there is no shared singleton.
- `sort(by:)` — use `plan(_:)` followed by `apply(_:)`.
- Photo deletion — PhotoSort does not delete photos.
- User interface — PhotoSort is a framework, not a UI component library.
- macOS support — PhotoSort targets iOS only.

Do not invent or suggest these APIs when integrating PhotoSort.
