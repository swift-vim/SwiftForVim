// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "__VIM_PLUGIN_NAME__",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "__VIM_PLUGIN_NAME__",
            targets: ["__VIM_PLUGIN_NAME__"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // SwiftForVim is moving fast, 
        // master for the latest and greatest
        .package(url: "https://github.com/swift-vim/SwiftForVim.git",
             .revision("__GIT_REVISION__"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "__VIM_PLUGIN_NAME__",
            dependencies: ["VimKit", "VimAsync"]),
        .testTarget(
            name: "__VIM_PLUGIN_NAME__Tests",
            dependencies: ["__VIM_PLUGIN_NAME__"]),
    ]
)
