# AsyncItemProvider

AsyncItemProvider provides extensions to NSItemProvider that allow loading content using Swift Concurrency.

It does this using the new [`Task.immediate` API in Swift 6.2](https://developer.apple.com/documentation/swift/task/immediate(name:priority:executorpreference:operation:)-9bghc) (but back-deploys to iOS 17-aligned releases via `Task.startOnMainActor`)

This technique has been used successfully in several places, including https://typo.inc.

## Usage

To load content from an item provider, call one of the concurrency-aware loader functions and retrieve an `ItemLoadTask`.

This has two things inside:

- A `Task` that is loading the content, whose value you can await
- A `Progress` that you can observe that reports the item loading progress.

```swift
func loadAndDisplayImage(_ provider: NSItemProvider) {
    let imageLoad = provider.fileLoadTask(for: .image)
    self.progressObservation = progress.observe(\.fractionCompleted) { progress, _ in
        self.updateProgress(progress.fractionCompleted)
    }

    // Once you've retrieved the load task, you can create an async context and await the load.
    Task {
        let imageFile = await imageLoad.value
        let uiImage = UIImage(contentsOf: imageFile)
        self.imageView.image = uiImage
    }
}
```

There are three Task-returning load handlers:

```swift
/// Loads the item from the NSItemProvider for the given UTType representation and returns
/// an ItemLoadTask that is actively loading the value.
func dataLoadTask(for type: UTType) -> ItemLoadTask<Data>

/// Loads an `NSItemProviderReading` object instance directly and returns an ItemLoadTask that
/// is actively loading the object.
func objectLoadTask<Object>(
    for object: Object.Type
) -> ItemLoadTask<Object> where Object: NSItemProviderReading

/// Loads a file URL for the given UTType representation and returns an `ItemLoadTask` that has a
/// reference to the loaded file.
func fileLoadTask(
    for type: UTType,
    openInPlace: Bool = false,
    temporaryDirectory: URL? = nil
) -> ItemLoadTask<LoadedFile>
```

### Note

Naïvely wrapping NSItemProvider's load handlers with `withCheckedContinuation` and friends runs into an issue
with UIDropInteraction: if you don't synchronously start loading the content before `performDrop` returns, it
will likely terminate the drop interaction before your load is scheduled.

As such, it is not safe to pass the NSItemProvider into a Task and start loading it later:

```swift
func dropInteraction(_ interaction: UIDropInteraction, performDrop session: any UIDropSession) {
    let itemProviders = session.items.map(\.itemProvider)

    // This Task here is not safe! UIDropInteraction may terminate the session before you start loading from
    // the item provider, which will _silently_ fail and _not_ call the completion handler.
    Task {
        for item in itemProviders {
            await withCheckedContinuation { continuation in
                item.loadFileRepresentation(...) { ... }
            }
        }
    }
}
``` 

## LICENSE

This project is released under the MIT license, a copy of which is available in this repository.

## Authors

Harlan Haskins ([harlan@harlanhaskins.com](mailto:harlan@harlanhaskins.com))
