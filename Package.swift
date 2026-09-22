// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Hybricons",

    platforms: [
        .macOS(.v13)
    ],

    products: [
        .plugin(
            name: "HybriconsPlugin",
            targets: ["HybriconsPlugin"]
        )
    ],

    targets: [
        .target(
            name: "CoreUIBridge",
            path: "Sources/CoreUIBridge",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("CoreGraphics")
            ]
        ),

        .executableTarget(
            name: "HybriconsBuilder",
            dependencies: [
                "CoreUIBridge"
            ]
        ),

        .plugin(
            name: "HybriconsPlugin",
            capability: .buildTool(),
            dependencies: [
                "HybriconsBuilder"
            ]
        )
    ]
)
