// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "__VIM_PLUGIN_NAME__",
    products: [
        .library(
            name: "__VIM_PLUGIN_NAME__",
            type: .dynamic,
            targets: ["__VIM_PLUGIN_NAME__"]),
    ],
    dependencies: [
        .package(url: "__GIT_REPO__",
             .revision("__GIT_REVISION__"))
    ],
    targets: [
        // Currently, it uses SPM, in a somewhat unconventional way due to
        // namespacing: It isn't possible to build Vim plugins with SPM
        // naievely.
        //
        // Consider SPM an implementation detail of the Makefile. See the
        // Makefile for more info.
        .target(
            name: "__VIM_PLUGIN_NAME__",
            // The dependencies of the target __VIM_PLUGIN_NAME__
            // are added in the Maekfile. Don't add here.
            dependencies: []),
        .testTarget(
            name: "__VIM_PLUGIN_NAME__Tests",
            dependencies: ["__VIM_PLUGIN_NAME__"]),
        // We cant depend on "Vim" due to namespacing issues
        // and SPM. This makes "Vim" available as a target.
        .target(name: "StubVimImport",
            dependencies: ["Vim", "VimAsync"])
    ]
)
