// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyICER",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyICER",
            targets: ["SwiftyICER", "ICERImpl"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyICER", dependencies: ["ICERImpl"]),
        .target(
            name: "ICERImpl",
            sources: ["icer_compression/lib_icer"],
            cSettings: [
                .headerSearchPath("icer_compression/lib_icer/inc"),
                .unsafeFlags(["-Wno-conversion"])
            ]
        ),
        .testTarget(
            name: "SwiftyICERTests",
            dependencies: ["SwiftyICER"]),
    ]
)
