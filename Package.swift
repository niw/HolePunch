// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HolePunch",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "holepunch", targets: [
            "HolePunch"
        ])
    ],
    dependencies: [
        .package(
            name: "swift-argument-parser",
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMajor(from: "0.4.4")
        )
    ],
    targets: [
        .target(
            name: "HolePunch",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
