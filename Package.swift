// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SecureBlur",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SecureBlur",
            targets: ["SecureBlur"]
        ),
    ],
    targets: [
        .target(
            name: "SecureBlur",
            path: "Sources"
        ),
        .testTarget(
            name: "SecureBlurTests",
            dependencies: ["SecureBlur"],
            path: "Tests/SecureBlurTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
