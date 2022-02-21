# AZCachedAsyncImage

An alternative to SwiftUI's `AsyncImage` with a built in caching mechanism.

### Installation

###### Swift Package Manager

1. Go to your Xcode project and select the Package Dependencies section.
2. Select the + button to add a new package.
3. Search for https://github.com/adamzarn/AZCachedAsyncImage in the search field.
4. Select Add Package.

### Usage

```swift
import AZCachedAsyncImage

AZCachedAsyncImage(url: URL(string: "https://example.com/icon.png")) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

