// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "memcached-cli-swift-kotlin",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "memcached-cli-swift-kotlin", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
        ]),
    ]
)