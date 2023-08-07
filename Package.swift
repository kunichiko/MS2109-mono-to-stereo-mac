// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mono-to-stereo",
    platforms: [
        .macOS(.v10_10)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "1.2.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "mono2stereo",
            dependencies: [
                .product(name: "ArgumentParser", package:"swift-argument-parser")
            ]),
        .testTarget(
            name: "mono2stereoTests",
            dependencies: ["mono2stereo"]),
    ]
)
