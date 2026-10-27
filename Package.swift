// swift-tools-version: 6.0
import PackageDescription
import Foundation

let plistPath = Context.packageDirectory + "/BibleStudy/Info.plist"

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
                .copy("Resources/Bibles.sqlite"),
                .copy("Resources/AppIcon.png"),
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/Assets.xcassets")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", plistPath
                ])
            ]
        )
    ]
)
