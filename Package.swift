// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mono-to-stereo",
    platforms: [
        .macOS(.v10_10)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "0.4.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "mono-to-stereo",
            dependencies: [
                .product(name: "ArgumentParser", package:"swift-argument-parser")
            ]),
        .testTarget(
            name: "mono-to-stereoTests",
            dependencies: ["mono-to-stereo"]),
    ]
)
