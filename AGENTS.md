# Repository Guidelines

## Project Overview
PhotoSort is an iOS-only Swift framework that organizes photos into albums based on dominant colors and recognized subjects.
The framework targets iOS 16.0 or later and uses Swift 6.

## Build and Test
Use Xcode and `xcodebuild` to build and test the project against an iOS Simulator.
First, inspect the available schemes:
```bash
xcodebuild -list
```

List available iOS simulators:
```bash
xcrun simctl list devices available
```

Build the framework:
```bash
xcodebuild \
  -scheme PhotoSort \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run the test suite using an available simulator:
```bash
xcodebuild \
  -scheme PhotoSort \
  -destination 'platform=iOS Simulator,name=<SIMULATOR_NAME>' \
  test
```
Replace `PhotoSort` with the actual scheme name if it differs, and `<SIMULATOR_NAME>` with an available simulator name.
**Do not use `swift test`.** This package is iOS-only and must be built and tested using Xcode with an iOS Simulator destination.

## Code Guidelines
- Use Swift 6 language features and concurrency checking.
- Respect `Sendable` requirements. Do not introduce unsafe concurrency without a clear justification.
- Add `///` documentation comments to every public declaration.
- Keep the public API small and focused.
- Prefer clear, explicit names and straightforward implementations.
- Avoid unnecessary abstractions and duplicated logic.
- Preserve the existing architecture and established design decisions.
- Do not add external package dependencies without a clear requirement and explicit approval.

## Documentation
- Keep public API documentation accurate and up to date.
- Update DocC documentation when public APIs or their behavior change.
- Ensure DocC links resolve correctly.
- Keep the README consistent with the actual implementation.

## Quality Requirements
- Builds must complete without warnings.
- Tests must pass before considering a change complete.
- Add or update tests when behavior changes.
- Do not weaken existing tests just to make a build pass.
- Do not claim that a build or test passed unless it was actually executed and verified.

## Scope and Compatibility
- Maintain iOS 16.0 as the minimum deployment target.
- Do not introduce macOS support or macOS-specific build assumptions.
- Do not add public APIs unless they are necessary for the framework's intended use.
- Do not implement functionality outside the framework's scope, such as photo deletion or user interface components.
