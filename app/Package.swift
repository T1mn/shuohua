// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Shuohua",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/T1mn/qwen3-asr-swift", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Shuohua",
            dependencies: [
                .product(name: "Qwen3ASR", package: "qwen3-asr-swift"),
                .product(name: "Qwen3Common", package: "qwen3-asr-swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ShuohuaTests",
            path: "Tests/ShuohuaTests"
        ),
    ]
)
