// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseExtend",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MouseExtend",
            targets: ["MouseExtend"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MouseExtend",
            path: "Sources/MouseExtend",
            swiftSettings: [
                .unsafeFlags([
                    "-plugin-path",
                    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
                ])
            ]
        )
    ]
)
