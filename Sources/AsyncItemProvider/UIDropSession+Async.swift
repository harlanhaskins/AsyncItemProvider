//
//  UIDropSession+Async.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers

@available(iOS 17.0, *)
@available(visionOS 1.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension UIDropSession {
    /// Creates a task that asynchronously loads objects of the specified class from the drop session.
    ///
    /// This method wraps `UIDropSession.loadObjects(ofClass:completion:)` to provide
    /// Swift concurrency support with progress tracking. The objects must conform to
    /// both `NSItemProviderReading` and `UIItemProviderReading`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // In a drop interaction delegate method
    /// let loadTask = dropSession.objectsLoadTask(for: UIImage.self)
    ///
    /// // Observe progress
    /// loadTask.progress.observe(\.fractionCompleted) { progress, _ in
    ///     updateProgressUI(progress.fractionCompleted)
    /// }
    ///
    /// // Await the results and use them
    /// Task {
    ///     let images = try await loadTask.task.value
    ///     for image in images {
    ///         processImage(image)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter objectType: The class type of the objects to load. Must conform to both
    ///   `NSItemProviderReading`.
    ///
    /// - Returns: An `ItemLoadTask` containing both the async task and progress tracker.
    ///   The task produces an array of loaded objects.
    @MainActor
    public func objectLoadTask(
        for objectType: any (NSItemProviderReading & Sendable).Type
    ) -> ItemLoadTask<[any (NSItemProviderReading & Sendable)], Never> {
        ItemLoadTask { continuation in
            self.loadObjects(ofClass: objectType) { objects in
                // The API will always return values of the provided Sendable type, but the load callback doesn't
                // enforce the Sendability. As such, we need to unsafeBitCast the whole array (which is safe-ish,
                // as long as the value actually is Sendable, because Sendable doesn't impose any ABI requirements)
                let sendableObjects = unsafeBitCast(objects, to: [any NSItemProviderReading & Sendable].self)
                continuation.resume(returning: sendableObjects)
            }
        }
    }
}
#endif
