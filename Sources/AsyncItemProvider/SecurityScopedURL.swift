//
//  SecurityScopedURL.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation

/// A wrapper around a URL that automatically manages security-scoped resource access.
///
/// When working with security-scoped URLs (such as those obtained from file representations
/// loaded in-place), you must call `startAccessingSecurityScopedResource()` before accessing
/// the file and `stopAccessingSecurityScopedResource()` when done. This class automates that
/// process by starting access on initialization and stopping access on deinitialization.
///
/// ## Usage
///
/// ```swift
/// let scopedURL = SecurityScopedURL(fileURL)
/// // Access the file via scopedURL.url
/// // Security scope is automatically released when scopedURL is deallocated
/// ```
///
/// - Note: This class is `Sendable` and thread-safe for use across concurrency domains.
/// - Important: The security-scoped resource access is automatically managed. You should not
///   manually call `startAccessingSecurityScopedResource()` or `stopAccessingSecurityScopedResource()`
///   on the wrapped URL.
public final class SecurityScopedURL: Sendable {
    /// The underlying URL with security-scoped access.
    public let url: URL

    /// Indicates whether the security scope was successfully started.
    ///
    /// This value is `true` if `startAccessingSecurityScopedResource()` returned `true`,
    /// meaning the URL required security-scoped access and it was successfully started.
    /// If `false`, the URL either didn't require scoped access or access couldn't be started.
    let isScoped: Bool

    /// Creates a security-scoped URL wrapper and begins accessing the security-scoped resource.
    ///
    /// - Parameter url: The URL to wrap and access. If the URL requires security-scoped access,
    ///   it will be automatically started.
    public init(_ url: URL) {
        self.isScoped = url.startAccessingSecurityScopedResource()
        self.url = url
    }

    deinit {
        if isScoped {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
