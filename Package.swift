// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BubbleTabBar",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "BubbleTabBar", targets: ["BubbleTabBar"]),
        .library(name: "BubbleTabBarDynamic", type: .dynamic, targets: ["BubbleTabBar"])
    ],
    targets: [
        .target(
            name: "BubbleTabBar",
            dependencies: []),
        .testTarget(
            name: "BubbleTabBarTests",
            dependencies: ["BubbleTabBar"]),
    ]
)
