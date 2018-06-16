// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Vim",
    products: [
        // VimKit is a Library for VimPlugin development
        .library(
            name: "VimKit",
            type: .static,
            targets: ["VimKit"]),

        .library(
            name: "VimInterface",
            type: .static,
            targets: ["VimInterface"]),

        .library(
            name: "VimAsync",
            type: .static,
            targets: ["VimAsync"]),

        .library(
            name: "Example",
            type: .dynamic,
            targets: ["Example"]),
    ],

    targets: [
        .target(name: "VimKit",
            dependencies: ["Vim"]),
        .target(name: "Vim",
            dependencies: ["VimInterface"]),

        .target(name: "VimInterface",
            dependencies: []),

        // Async Support for Vim. Note, that this is OSX only and
        // depends on Foundation
        .target(name: "VimAsync",
            dependencies: ["VimKit"]),

        // Tests
        .testTarget(
            name: "VimInterfaceTests",
            dependencies: ["VimInterface", "Example"]),
        .testTarget(
            name: "VimKitTests",
            dependencies: ["VimKit", "Example"]),

        // Example
        .target(name: "Example",
            dependencies: ["VimKit", "VimAsync"]),
    ]
)
