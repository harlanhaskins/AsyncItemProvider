//
//  NSItemProvider+Async.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation
import UniformTypeIdentifiers

extension NSItemProvider {
    static let defaultTemporaryDirectory = URL.temporaryDirectory.appending(path: "AsyncItemProvider-TemporaryFiles")

    /// Creates a task that asynchronously loads a data representation for the specified type.
    ///
    /// This method wraps `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`
    /// to provide Swift concurrency support with progress tracking.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Do this in a non-async context.
    /// let loadTask = itemProvider.dataLoadTask(for: .png)
    ///
    /// // Observe progress
    /// loadTask.progress.observe(\.fractionCompleted) { progress, _ in
    ///     print("Loading: \(progress.fractionCompleted * 100)%")
    /// }
    ///
    /// // Await the result and use it
    /// Task {
    ///     let imageData = try await loadTask.task.value
    ///     let image = UIImage(data: imageData)
    ///     displayImage(imageData)
    /// }
    /// ```
    ///
    /// - Parameter type: The uniform type identifier for the desired data representation.
    /// - Returns: An `ItemLoadTask` containing both the async task and progress tracker.
    /// - Throws: `ItemLoadingError.noData` if no data is returned
    /// - Throws: Any error from the underlying loading operation.
    @MainActor
    public func dataLoadTask(for type: UTType) -> ItemLoadTask<Data> {
        ItemLoadTask { continuation in
            self.loadDataRepresentation(for: type) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                }
            }
        }
    }

    /// Creates a task that asynchronously loads an object of the specified class.
    ///
    /// This method wraps `NSItemProvider.loadObject(ofClass:completionHandler:)`
    /// to provide Swift concurrency support with progress tracking.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Do this in a non-async context.
    /// let loadTask = itemProvider.objectLoadTask(for: UIImage.self)
    ///
    /// // Observe progress
    /// loadTask.progress.observe(\.fractionCompleted) { progress, _ in
    ///     print("Loading: \(progress.fractionCompleted * 100)%")
    /// }
    ///
    /// // Await the result and use it
    /// Task {
    ///     let image = try await loadTask.task.value
    ///     displayImage(image)
    /// }
    /// ```
    ///
    /// - Parameter object: The class type of the object to load. Must conform to `NSItemProviderReading`.
    /// - Returns: An `ItemLoadTask` containing both the async task and progress tracker.
    /// - Throws: `ItemLoadingError.noData` if no object is returned or if the returned object
    ///   cannot be cast to the requested type
    /// - Throws: Any error from the underlying loading operation.
    @MainActor
    public func objectLoadTask<Object>(
        for object: Object.Type
    ) -> ItemLoadTask<Object> where Object: NSItemProviderReading {
        ItemLoadTask { continuation in
            self.loadObject(ofClass: Object.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let object = object as? Object {
                    continuation.resume(returning: object)
                } else {
                    continuation.resume(throwing: ItemLoadingError.noData)
                }
            }
        }
    }

    private static func moveFile(at url: URL, toTemporaryDirectory temporaryDirectory: URL?) throws -> URL {
        let finalDirectory = (temporaryDirectory ?? Self.defaultTemporaryDirectory).appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: finalDirectory, withIntermediateDirectories: true)
        let endFile = finalDirectory.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.moveItem(at: url, to: endFile)
        return endFile
    }

    /// Creates a task that asynchronously loads a file representation for the specified type.
    ///
    /// This method wraps `NSItemProvider.loadFileRepresentation(forTypeIdentifier:completionHandler:)`
    /// to provide Swift concurrency support with progress tracking. The file can be either copied
    /// to a temporary location or accessed in-place with an automatically-managed security scope.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Copy the file to a temporary location
    /// let loadTask = itemProvider.fileLoadTask(for: .pdf)
    /// Task {
    ///     let file = try await loadTask.task.value
    ///     if case .copied(let url) = file {
    ///         processFile(at: url)
    ///     }
    /// }
    ///
    /// // Or access the file in-place with security scope
    /// let loadTask = itemProvider.fileLoadTask(for: .pdf, openInPlace: true)
    /// Task {
    ///     let file = try await loadTask.task.value
    ///     if case .inPlace(let scopedURL) = file {
    ///         processFile(at: scopedURL.url)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The uniform type identifier for the desired file representation.
    ///   - openInPlace: If `true`, the file is accessed at its original location with
    ///     security-scoped access. If `false` (default), the file is copied to a temporary location.
    ///   - temporaryDirectory: Optional custom directory for temporary file copies. If `nil`,
    ///     a default temporary directory is used. Only applies when `openInPlace` is `false`.
    ///
    /// - Returns: An `ItemLoadTask` containing both the async task and progress tracker.
    ///   The task produces a `LoadedFile` indicating how the file was accessed.
    ///
    /// - Throws: `ItemLoadingError.noData` if no file URL is returned
    /// - Throws: Any error from the underlying loading operation or file system operations.
    @MainActor
    public func fileLoadTask(
        for type: UTType,
        openInPlace: Bool = false,
        temporaryDirectory: URL? = nil
    ) -> ItemLoadTask<LoadedFile> {
        ItemLoadTask { continuation in
            self.loadFileRepresentation(
                for: type,
                openInPlace: openInPlace
            ) { url, isInPlace, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url else {
                    continuation.resume(throwing: ItemLoadingError.noData)
                    return
                }

                if openInPlace {
                    let scoped = SecurityScopedURL(url)
                    continuation.resume(returning: .inPlace(scoped))
                } else {
                    do {
                        let endFile = try Self.moveFile(at: url, toTemporaryDirectory: temporaryDirectory)
                        continuation.resume(returning: .copied(endFile))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
