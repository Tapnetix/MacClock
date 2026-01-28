// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacClock",
            path: "MacClock"
        ),
        .testTarget(
            name: "MacClockTests",
            dependencies: ["MacClock"],
            path: "MacClockTests"
        )
    ]
)
