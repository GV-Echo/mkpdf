import Foundation
import PackagePlugin

/// Embeds everything under `Assets/` into the target as generated Swift source,
/// so the binary needs no resource bundle next to it.
@main
struct AssetPackerPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let assets = context.package.directoryURL.appending(path: "Assets")
        let output = context.pluginWorkDirectoryURL.appending(path: "GeneratedAssets.swift")
        return [
            .buildCommand(
                displayName: "Packing Assets",
                executable: try context.tool(named: "AssetPacker").url,
                arguments: [assets.path(), output.path()],
                inputFiles: try files(under: assets),
                outputFiles: [output]
            )
        ]
    }

    private func files(under directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        return try (enumerator?.allObjects as? [URL] ?? []).filter {
            try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }
    }
}
