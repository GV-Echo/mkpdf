// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mkpdf",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "mkpdf", dependencies: ["MkpdfCore"]),
        .target(name: "MkpdfCore", plugins: ["AssetPackerPlugin"]),
        .executableTarget(name: "AssetPacker"),
        .plugin(
            name: "AssetPackerPlugin",
            capability: .buildTool(),
            dependencies: ["AssetPacker"]
        ),
        .testTarget(
            name: "MkpdfCoreTests",
            dependencies: ["MkpdfCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
