// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWYouTubePlayerView",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "WWYouTubePlayerView", targets: ["WWYouTubePlayerView"]),
    ],
    targets: [
        .target(name: "WWYouTubePlayerView", resources: [.process("Resources"), .copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
