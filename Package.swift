// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwitchPoint",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SwitchPointCore",
            targets: ["SwitchPointCore"]
        ),
        .executable(
            name: "SwitchPointApp",
            targets: ["SwitchPointApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwitchPointCore",
            dependencies: [],
            path: "Sources/SwitchPointCore"
        ),
        .executableTarget(
            name: "SwitchPointApp",
            dependencies: ["SwitchPointCore"],
            path: "Sources/SwitchPointApp"
        ),
        .testTarget(
            name: "SwitchPointCoreTests",
            dependencies: ["SwitchPointCore"],
            path: "Tests/SwitchPointCoreTests"
        )
    ]
)
