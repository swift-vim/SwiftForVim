// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Vim",
    products: [
        .library(
            name: "VimInterface",
            type: .static,
            targets: ["VimInterface"]),

        .library(
            name: "Vim",
            type: .static,
            targets: ["Vim"]),

        .library(
            name: "VimPluginBootstrap",
            type: .static,
            targets: ["VimPluginBootstrap"]),

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
        .target(name: "Vim",
            dependencies: ["VimInterface", "VimPluginBootstrap"]),

        .target(name: "VimInterface",
            dependencies: []),

        .target(name: "VimPluginBootstrap",
            dependencies: []),

        // Async Support for Vim. Note, that this is OSX only and
        // depends on Foundation
        .target(name: "VimAsync",
            dependencies: []),

        // Tests
        .testTarget(
            name: "VimInterfaceTests",
            dependencies: ["VimInterface"]),
        .testTarget(
            name: "VimTests",
            dependencies: []),

        // Example:
        .target(name: "Example",
            dependencies: []),
    ]
)
