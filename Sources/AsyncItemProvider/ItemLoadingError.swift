//
//  ItemLoadingError.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation

/// Errors that can occur when loading items from an `NSItemProvider`.
///
/// These errors represent failures specific to the item loading process,
/// distinct from underlying system or framework errors that may also be thrown.
public enum ItemLoadingError: Error {
    /// The item provider completed without returning any data.
    ///
    /// This error is thrown when a loading operation completes successfully
    /// from the system's perspective, but the expected data or object is `nil`.
    /// This can occur when:
    /// - The requested type isn't available in the provider
    /// - The data representation is empty
    /// - Object loading returns `nil` despite no explicit error
    case noData
}
