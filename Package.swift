// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChatInNotch",
    platforms: [.macOS("27.0")],
    targets: [
        .executableTarget(
            name: "ChatInNotch",
            path: "Sources/ChatInNotch",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
