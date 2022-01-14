// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TealiumBraze",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "TealiumBraze", targets: ["TealiumBraze"])
    ],
    dependencies: [
        .package(url: "https://github.com/tealium/tealium-swift", .upToNextMajor(from: "2.6.0")),
        .package(url: "https://github.com/Appboy/appboy-ios-sdk", .upToNextMajor(from: "4.4.1"))
    ],
    targets: [
        .target(
            name: "TealiumBraze",
            dependencies: [
                .product(name: "AppboyUI", package: "appboy-ios-sdk"),
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