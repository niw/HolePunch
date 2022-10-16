// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HolePunch",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "holepunch",
            targets: [
                "HolePunch"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.1.4"
        )
    ],
    targets: [
        .executableTarget(
            name: "HolePunch",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        )
    ]
)
