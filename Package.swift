// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OllamaUsageWidget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "OllamaUsageWidget", path: "Sources/OllamaUsageWidget"),
        .testTarget(name: "OllamaUsageWidgetTests", dependencies: ["OllamaUsageWidget"], path: "Tests/OllamaUsageWidgetTests"),
    ]
)
