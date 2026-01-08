// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetLimiter",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NetLimiter",
            path: "NetLimiter"
        )
    ]
)
