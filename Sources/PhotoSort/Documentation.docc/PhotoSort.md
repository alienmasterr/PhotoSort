# PhotoSort

PhotoSort is a Swift framework for organizing photos in an iOS photo library into albums based on their dominant colors and recognized subjects.

The framework provides a two-step workflow: create a sorting plan with `PhotoSorter.plan(_:)`, review the proposed albums, and apply the plan with `PhotoSorter.apply(_:)`.

PhotoSort uses Apple's Vision framework for subject recognition and the Photos framework to access and organize the photo library.

## Topics

### Essentials

- ``PhotoSorter``
- ``PhotoSorter/Configuration``

### Requests

- ``SortRequest``
- ``Subject``
- ``NamedColor``
- ``ColorSelection``

### Results

- ``SortPlan``
- ``SortResult``
- ``SortProgress``

### Errors

- ``SortError``
