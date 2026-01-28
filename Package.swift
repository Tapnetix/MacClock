// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacClock",
            path: "MacClock",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/Fonts")
            ]
        ),
        .testTarget(
            name: "MacClockTests",
            dependencies: ["MacClock"],
            path: "MacClockTests"
        )
    ]
)
