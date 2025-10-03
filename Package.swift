// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AsyncItemProvider",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "AsyncItemProvider",
            targets: ["AsyncItemProvider"]
        ),
    ],
    targets: [
        .target(name: "AsyncItemProvider")
    ]
)
