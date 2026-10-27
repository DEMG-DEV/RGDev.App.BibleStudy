// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BibleStudy",
    defaultLocalization: "es",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "BibleStudy",
            targets: ["BibleStudy"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BibleStudy",
            dependencies: [],
            path: "BibleStudy/Sources",
            resources: [
                .copy("Resources/Bibles.sqlite")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
