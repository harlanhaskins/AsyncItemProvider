//
//  ItemLoadTask.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation

/// A container that pairs an asynchronous task with its associated progress tracker.
///
/// When loading items from an `NSItemProvider`, operations can be long-running and may
/// benefit from progress reporting. This structure combines a Swift concurrency `Task`
/// with a `Progress` object to enable both async/await patterns and progress observation.
///
/// ## Usage
///
/// ```swift
/// // Load synchronously
/// let loadTask = itemProvider.dataLoadTask(for: .png)
///
/// // Observe progress
/// loadTask.progress.observe(\.fractionCompleted) { progress, _ in
///     print("Progress: \(progress.fractionCompleted * 100)%")
/// }
///
/// // Await the result in a Task.
/// Task {
///     let data = try await loadTask.task.value
///     useData(data)
/// }
/// ```
///
/// - Note: The generic type `Value` must conform to `Sendable` to ensure thread-safe transfer
///   across concurrency domains.
public struct ItemLoadTask<Value: Sendable, Failure: Error> {
    /// The asynchronous task that performs the loading operation.
    ///
    /// You can await this task's `value` property to retrieve the loaded item,
    /// or call `cancel()` to cancel the operation.
    public var task: Task<Value, Failure>

    /// The progress object tracking the loading operation.
    ///
    /// This can be used to observe progress updates, display progress UI,
    /// or integrate with parent progress objects.
    public var progress: Progress

    @MainActor
    internal init(
        wrappingProgress function: @escaping (CheckedContinuation<Value, Error>) -> Progress
    ) where Failure == Error {
        let progress = Progress(totalUnitCount: 1)
        let task = Task.immediateOnMain {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Value, Error>) in
                let childProgress = function(continuation)
                progress.addChild(childProgress, withPendingUnitCount: 1)
            }
        }
        self.task = task
        self.progress = progress
    }

    @MainActor
    internal init(
        wrappingProgress function: @escaping (CheckedContinuation<Value, Never>) -> Progress
    ) where Failure == Never {
        let progress = Progress(totalUnitCount: 1)
        let task = Task.immediateOnMain {
            await withCheckedContinuation { (continuation: CheckedContinuation<Value, Never>) in
                let childProgress = function(continuation)
                progress.addChild(childProgress, withPendingUnitCount: 1)
            }
        }
        self.task = task
        self.progress = progress
    }
}
