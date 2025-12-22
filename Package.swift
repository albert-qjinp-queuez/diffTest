// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiffTest",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        // Here we define our package's external dependencies
        // and from where they can be fetched:
        .package(
            url: "https://github.com/a7ex/xcresultparser",
                .upToNextMajor(from: "1.9.0")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
                .upToNextMajor(from: "1.6.1")
        ),
        .package(
            url: "https://github.com/davidahouse/XCResultKit.git",
            exact: "1.2.2"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "DiffTest",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                "XCResultKit",
            ]
        ),
    ]
)
