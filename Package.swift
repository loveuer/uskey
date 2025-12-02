// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "uskey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "uskey", targets: ["uskey"])
    ],
    targets: [
        .executableTarget(
            name: "uskey",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-Xfrontend", "-warn-concurrency"]),
                .unsafeFlags(["-Xfrontend", "-enable-actor-data-race-checks"])
            ]),
    ]
)