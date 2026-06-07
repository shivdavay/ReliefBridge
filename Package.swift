// swift-tools-version: 5.9
// Package.swift — ReliefBridge Insight
//
// This file declares the Swift Package Manager dependencies for the project.
// To use these packages in Xcode:
//   1. Open the .xcodeproj in Xcode (create via File → New → Project, iOS App, SwiftUI lifecycle)
//   2. Go to File → Add Package Dependencies…
//   3. Add each URL listed below
//
// Swift Charts is a built-in Apple framework (iOS 16+) — no SPM entry needed.

import PackageDescription

let package = Package(
    name: "ReliefBridge",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ReliefBridge",
            targets: ["ReliefBridge"]
        )
    ],
    dependencies: [
        // Property-based testing framework used for all correctness property tests.
        // https://github.com/typelift/SwiftCheck
        .package(
            url: "https://github.com/typelift/SwiftCheck.git",
            from: "0.12.0"
        ),

        // Snapshot testing library for Aviation Dark Mode appearance tests.
        // https://github.com/pointfreeco/swift-snapshot-testing
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.15.0"
        )
    ],
    targets: [
        .target(
            name: "ReliefBridge",
            dependencies: [],
            path: "ReliefBridge",
            exclude: ["App/ReliefBridgeApp.swift", "README.md"]
        ),
        .testTarget(
            name: "ReliefBridgeTests",
            dependencies: [
                "ReliefBridge",
                .product(name: "SwiftCheck", package: "SwiftCheck"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "ReliefBridgeTests"
        )
    ]
)
