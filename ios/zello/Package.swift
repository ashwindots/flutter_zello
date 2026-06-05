// swift-tools-version: 5.9
// Swift Package Manager manifest used by Flutter (>= 3.24) when SPM-enabled
// host apps consume the plugin. The same sources are also packaged via the
// CocoaPods podspec one level up.
import PackageDescription

let package = Package(
    name: "zello",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "zello", targets: ["zello"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "zello",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
