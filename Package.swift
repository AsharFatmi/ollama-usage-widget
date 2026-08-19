// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OllamaUsageWidget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "OllamaUsageWidget", path: "Sources/OllamaUsageWidget"),
        .testTarget(
            name: "OllamaUsageWidgetTests",
            dependencies: ["OllamaUsageWidget"],
            path: "Tests/OllamaUsageWidgetTests",
            swiftSettings: [
                // Homebrew Swift 6.3.3's Testing framework is macOS-26-only; the
                // _Testing_Foundation cross-import overlay breaks at the macOS 14
                // target. Disable overlay search (see T3 worker notes).
                .unsafeFlags(["-Xfrontend", "-disable-cross-import-overlay-search"]),
            ]
        ),
    ]
)
