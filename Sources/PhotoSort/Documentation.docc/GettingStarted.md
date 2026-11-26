# Getting Started

Learn how to install PhotoSort, configure photo library permissions, and perform your first sorting operation.

## Requirements

- iOS 16.0 or later
- Swift 6.0
- Xcode 16.0 or later

PhotoSort is designed for iOS and does not support macOS.

## Installation

PhotoSort can be added to your project using Swift Package Manager.

### Using Xcode

1. Open your project in Xcode.
2. Select **File → Add Package Dependencies**.
3. Enter the URL of the PhotoSort repository.
4. Select a version starting from `1.0.0`.
5. Add the `PhotoSort` library to your app target.

### Using Package.swift

Add PhotoSort to the package dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/alienmasterr/PhotoSort",
        from: "1.0.0"
    )
]
```

Then add the library to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "PhotoSort"
    ]
)
```

## Photo Library Permission

Before using PhotoSort, add the `NSPhotoLibraryUsageDescription` key to your app's `Info.plist` file.

Provide a description explaining why your application needs access to the photo library:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoSort needs access to your photo library to analyze and organize your photos into albums.</string>
```

The host application is responsible for providing this key. PhotoSort requests photo library access when a sorting operation is performed.

## Your First Sorting Operation

PhotoSort uses a two-step workflow:

1. Create a sorting plan using ``PhotoSorter/plan(_:)``.
2. Apply the plan using ``PhotoSorter/apply(_:)``.

First, import the framework and create a sorter:

```swift
import PhotoSort

let sorter = PhotoSorter()
```

Define the period to process:

```swift
let period = DateInterval(
    start: Calendar.current.date(
        from: DateComponents(year: 2026, month: 1, day: 1)
    )!,
    end: Calendar.current.date(
        from: DateComponents(year: 2027, month: 1, day: 1)
    )!
)
```

Create a request to sort photos by subject:

```swift
let request = try SortRequest(
    period: period,
    subject: .cats
)
```

Generate a sorting plan:

```swift
let plan = try await sorter.plan(request)
```

The planning step analyzes the accessible photos and returns a ``SortPlan``. It does not modify the photo library.

You can inspect the proposed albums before applying the plan:

```swift
for album in plan.albums {
    print("\(album.title): \(album.photoCount) photos")
}
```

When you are ready, apply the plan:

```swift
let result = try await sorter.apply(plan)
```

The framework creates the required albums and adds photos that are not already present.

The operation returns a ``SortResult`` containing information about the changes made to the photo library.

## Next Steps

- <doc:PhotoSort> — explore the framework's main API.
- ``SortRequest`` — learn how to configure sorting criteria.
- ``SortPlan`` — understand the proposed sorting operations.
- ``SortResult`` — inspect the results of applying a plan.
