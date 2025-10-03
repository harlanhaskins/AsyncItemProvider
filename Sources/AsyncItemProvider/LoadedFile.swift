//
//  LoadedFile.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation

/// Represents a file loaded from an `NSItemProvider`, indicating how it was accessed.
///
/// When loading file representations from an `NSItemProvider`, the file can be accessed
/// in two different ways depending on the `openInPlace` parameter:
///
/// - **Copied**: The file is copied to a temporary location that your app can access freely
/// - **In-place**: The file is accessed at its original location with security-scoped access
///
/// ## Usage
///
/// ```swift
/// let loadTask = itemProvider.fileLoadTask(for: .pdf, openInPlace: true)
/// let file = try await loadTask.task.value
///
/// switch file {
/// case .copied(let url):
///     // File was copied to a temporary location
///     // You can access it freely until it's deleted
///     processFile(at: url)
///
/// case .inPlace(let scopedURL):
///     // File is accessed in-place with security scope
///     // When the `SecurityScopedURL` is deallocated, the security-scoped access of this file will be lost.
///     processFile(at: scopedURL.url)
/// }
/// ```
///
/// - Note: This enum is `Sendable` and can be safely passed across concurrency domains.
public enum LoadedFile: Sendable {
    /// The file was copied to a temporary location.
    ///
    /// The associated URL points to a copy of the file that your app can access without
    /// security-scoped restrictions. The file is placed in a temporary directory and
    /// should be deleted when no longer needed.
    case copied(URL)

    /// The file is accessed in-place at its original location.
    ///
    /// The associated `SecurityScopedURL` provides access to the file at its original
    /// location with automatic management of security-scoped resource access.
    ///
    /// In order to keep the file accessible, either keep this SecurityScopedURL instance
    /// alive or manually manage references to the URL with
    /// `url.[start|stop]AccessingSecurityScopedResource()`.
    case inPlace(SecurityScopedURL)

    /// The URL of the loaded file, regardless of how it was accessed.
    ///
    /// This computed property provides convenient access to the file URL for both
    /// `.copied` and `.inPlace` cases:
    /// - For `.copied`, returns the temporary file URL
    /// - For `.inPlace`, returns the security-scoped URL
    public var url: URL {
        switch self {
        case let .copied(url):
            url
        case let .inPlace(scoped):
            scoped.url
        }
    }
}
