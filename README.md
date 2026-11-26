# PhotoSort
PhotoSort is a Swift framework that organizes photos in the iOS photo library into albums based on their dominant colors and recognized subjects.
## Features
- **Color-based sorting** — analyzes dominant colors in photos and groups them into color-specific albums.
- **Subject recognition** — uses Apple's Vision framework to identify supported subjects, such as cats and dogs.
- **Combined sorting** — groups photos by both dominant color and recognized subject.
- **Customizable filtering** — supports selecting specific colors or subjects to include in the sorting process.
- **Dry-run planning** — generates a sorting plan without modifying the photo library, allowing you to review the results before applying them.
- **Duplicate prevention** — checks existing album contents and adds only photos that are not already present.
- **Progress reporting** — provides progress updates during photo analysis.
- **Concurrent processing** — analyzes multiple photos concurrently with a configurable concurrency limit.
- **Cancellation support** — allows ongoing sorting operations to be cancelled.
## Requirements
- iOS 16.0 or later
- Swift 6.0
- Xcode 16.0 or later
PhotoSort is designed for iOS and does not support macOS.
## Installation
PhotoSort can be added to project using Swift Package Manager.
### Using Xcode
1. Open your project in Xcode.
2. Select **File → Add Package Dependencies**.
3. Enter the URL of the PhotoSort repository.
4. Select the version you want to use.
5. Add the `PhotoSort` library to your app target.

### Using Package.swift
Add PhotoSort to the dependencies in your `Package.swift` file:
```swift
dependencies: [
    .package(
        url: "https://github.com/alienmasterr/PhotoSort",
        from: "1.0.0"
    )
]
```

Then add `PhotoSort` to the dependencies of your target:
```swift
.target(
    name: "YourApp",
    dependencies: [
        "PhotoSort"
    ]
)
```
## Configuration
PhotoSort requires access to the user's photo library. Before using the framework, add the NSPhotoLibraryUsageDescription key to your app's Info.plist file.
Provide a clear explanation of why your app needs access to photos:
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoSort needs access to photo library to analyze and organize your photos into albums.</string>
The host application is responsible for providing this usage description. PhotoSort requests photo library access when plan or apply is called.
## Usage
Import PhotoSort and create a `PhotoSorter` instance:
```swift
import PhotoSort

let sorter = PhotoSorter()

let period = DateInterval(
    start: Calendar.current.date(
        from: DateComponents(year: 2026, month: 1, day: 1)
    )!,
    end: Calendar.current.date(
        from: DateComponents(year: 2027, month: 1, day: 1)
    )!
)
```
All sorting requests use a `DateInterval` to specify which photos to process.
### Sort by colors
To group photos by all supported colors:
```swift
let request = try SortRequest(
    period: period,
    colors: .all
)

let plan = try await sorter.plan(request)
let result = try await sorter.apply(plan)
```

To select specific colors, use `ColorSelection.only`:
```swift
let request = try SortRequest(
    period: period,
    colors: .only([.red, .yellow, .blue])
)
```

### Sort by subject
To group photos by a recognized subject:
```swift
let request = try SortRequest(
    period: period,
    subject: .cats
)

let plan = try await sorter.plan(request)
let result = try await sorter.apply(plan)
```

PhotoSort provides predefined subjects such as `.cats` and `.dogs`. You can also choose a custom subject:
```swift
let subject = Subject(label: "bird")
```
The subject must be supported by the underlying Vision classifier.

### Sort by both colors and subjects
You can combine color and subject criteria to create more specific albums:
```swift
let request = try SortRequest(
    period: period,
    subject: .cats,
    colors: .only([.yellow, .blue])
)

let plan = try await sorter.plan(request)
let result = try await sorter.apply(plan)
```
For example, photos of cats with dominant yellow or blue colors are grouped into separate albums.

### Preview a sorting plan (dry run)
Use `plan` to analyze photos and generate a sorting plan without modifying the photo library:
```swift
let plan = try await sorter.plan(request)

for album in plan.albums {
    print("\(album.title): \(album.photoCount) photos")
}
```
The returned `SortPlan` contains the proposed albums and their photo identifiers, as well as scanning statistics.

To apply the plan and make changes to the photo library, call:
```swift
let result = try await sorter.apply(plan)
```
Applying a plan creates albums when necessary and adds only photos that are not already present.
## Limitations
- **Screenshots are skipped** — PhotoSort does not include screenshots in the sorting process.
- **iCloud Photos** — photos stored in iCloud may need to be downloaded before they can be analyzed. This can increase processing time and may require an internet connection.
- **Limited photo library access** — when the user grants limited access, PhotoSort can process only the photos selected by the user. Photos outside the accessible collection are not available to the framework.
- **Photo library permissions** — sorting operations require the appropriate photo library permissions. If access is denied, the operation fails with an access error.
## Documentation
PhotoSort uses Swift documentation comments to describe its public API.
You can generate browsable API documentation in Xcode using DocC:
1. Open the PhotoSort package in Xcode.
2. Select **Product → Build Documentation**.
3. Browse the generated documentation to explore public types, methods, and configuration options.
The documentation covers the framework's public API, including sorting requests, configuration, sorting plans, and results.
## Agents
PhotoSort provides a skill for AI coding agents. The skill contains project-specific instructions to help agents understand the framework's architecture, public API, conventions, and development workflow.
### Installing the skill
1. Locate the `SKILL.md` file in the PhotoSort repository.
2. Copy the skill directory into your AI agent's skills directory.
3. Restart or refresh your AI agent so it can discover the skill.

Refer to your AI agent's documentation for its supported skill installation location and format.
## Licence
PhotoSort is available under the MIT License. See the LICENSE file for details.
## AI usage in development
- decomposition
- comments and documantation lexical formulation
- testing and bug-fixing
- domain specific logic (such as color theory)
- proper naming


