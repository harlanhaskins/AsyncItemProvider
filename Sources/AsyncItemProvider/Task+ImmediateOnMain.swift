// This defines main-actor, backwards compatible shims for `Task.immediate` that deploy back to iOS 17 and macOS 14.

extension Task where Failure == Never {
    @MainActor
    @discardableResult
    @inlinable
    static func immediateOnMain(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ work: consuming @Sendable @escaping @MainActor () async -> Success
    ) -> Task<Success, Never> {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            .immediate(name: name, priority: priority, operation: work)
        } else {
            .startOnMainActor(priority: priority, work)
        }
    }
}

extension Task where Failure == Error {
    @MainActor
    @discardableResult
    @inlinable
    static func immediateOnMain(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ work: consuming @Sendable @escaping @MainActor () async throws -> Success
    ) -> Task<Success, Error> {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            .immediate(name: name, priority: priority, operation: work)
        } else {
            .startOnMainActor(priority: priority, work)
        }
    }
}

/// These declarations are ABI and are available in all of our supported deployment targets.

extension Task where Failure == Never {
    @_silgen_name("$sScTss5NeverORs_rlE16startOnMainActor8priority_ScTyxABGScPSg_xyYaYbScMYccntFZ")
    @MainActor
    @discardableResult
    @usableFromInline
    static func startOnMainActor(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ work: consuming @Sendable @escaping @MainActor () async -> Success
    ) -> Task<Success, Never>
}

extension Task where Failure == Error {
    @_silgen_name("$sScTss5Error_pRs_rlE16startOnMainActor8priority_ScTyxsAA_pGScPSg_xyYaYbKScMYccntFZ")
    @MainActor
    @discardableResult
    @usableFromInline
    static func startOnMainActor(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ work: consuming @Sendable @escaping @MainActor () async throws -> Success
    ) -> Task<Success, Error>
}
