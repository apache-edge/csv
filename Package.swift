// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CSV",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1),
        // Cross-platform support implicitly via Swift compiler itself
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CSV",
            targets: ["CSV"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies required
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CSV",
            dependencies: [],
            swiftSettings: [
                // Use conditional compilation for different platforms
                .define("CROSS_PLATFORM"),
            ]
        ),
        .testTarget(
            name: "CSVTests",
            dependencies: ["CSV"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
