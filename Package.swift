// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TealiumBraze",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "TealiumBraze", targets: ["TealiumBraze"])
    ],
    dependencies: [
        .package(url: "https://github.com/tealium/tealium-swift", .upToNextMajor(from: "2.12.0")),
        .package(url: "https://github.com/braze-inc/braze-swift-sdk", .upToNextMajor(from: "7.2.0"))
    ],
    targets: [
        .target(
            name: "TealiumBraze",
            dependencies: [
                .product(name: "BrazeKit", package: "braze-swift-sdk"),
                .product(name: "TealiumCore", package: "tealium-swift"),
                .product(name: "TealiumRemoteCommands", package: "tealium-swift")
            ],
            path: "./Sources"),
        .testTarget(
            name: "TealiumBrazeTests",
            dependencies: [
                .target(name: "TealiumBraze")
            ],
            path: "./Tests")
    ]
)
