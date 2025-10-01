//
//  NSItemProvider+Async.swift
//  AsyncItemProvider
//
//  Created by Harlan Haskins on 10/1/25.
//

import Foundation
import UniformTypeIdentifiers

public final class SecurityScopedURL: Sendable {
    let url: URL
    let isScoped: Bool

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

public struct ItemLoadTask<T: Sendable> {
    public var task: Task<T, Error>
    public var progress: Progress
}

public enum ItemLoadingError: Error {
    case noData
}

public enum LoadedFile: Sendable {
    case copied(URL)
    case inPlace(SecurityScopedURL)

    public var url: URL {
        switch self {
        case let .copied(url):
            url
        case let .inPlace(scoped):
            scoped.url
        }
    }
}

extension NSItemProvider {
    static let defaultTemporaryDirectory = URL.temporaryDirectory.appending(path: "AsyncItemProvider-TemporaryFiles")

    @MainActor
    private func wrapProgress<T>(_ function: @escaping (CheckedContinuation<T, Error>) -> Progress) -> ItemLoadTask<T> {
        let progress = Progress(totalUnitCount: 1)
        let task = Task.immediateOnMain {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
                let childProgress = function(continuation)
                progress.addChild(childProgress, withPendingUnitCount: 1)
            }
        }
        return ItemLoadTask(task: task, progress: progress)
    }

    @MainActor
    public func dataLoadTask(for type: UTType) -> ItemLoadTask<Data> {
        wrapProgress { continuation in
            self.loadDataRepresentation(for: type) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                }
            }
        }
    }

    @MainActor
    public func objectLoadTask<Object>(
        for object: Object.Type
    ) -> ItemLoadTask<Object> where Object: NSItemProviderReading {
        wrapProgress { continuation in
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

    @MainActor
    public func fileLoadTask(
        for type: UTType,
        openInPlace: Bool = false,
        temporaryDirectory: URL? = nil
    ) -> ItemLoadTask<LoadedFile> {
        wrapProgress { continuation in
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
