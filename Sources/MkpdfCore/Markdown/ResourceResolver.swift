import Foundation

/// Finds the files a note refers to: Markdown image paths relative to the note, and
/// Obsidian embeds (`![[name]]`), which Obsidian resolves anywhere in the vault.
final class ResourceResolver {
    /// A folder containing this is an Obsidian vault root.
    static let vaultMarker = ".obsidian"

    private let documentDirectory: URL
    private let vaultRoot: URL?
    private lazy var vaultFiles: [URL] = vaultRoot.map(Self.files(under:)) ?? []

    init(document: URL) {
        documentDirectory = document.deletingLastPathComponent()
        vaultRoot = Self.vaultRoot(containing: documentDirectory)
    }

    /// `reference` is the image path as written in Markdown, possibly percent-encoded.
    func image(reference: String) -> URL? {
        let path = reference.removingPercentEncoding ?? reference
        let url: URL?
        if path.hasPrefix("file://") {
            url = URL(string: path)
        } else if path.hasPrefix("/") {
            url = URL(filePath: path)
        } else {
            url = documentDirectory.appending(path: path)
        }
        return url.flatMap(existingFile)
    }

    /// `name` is the embed target: a file name or a vault-relative path.
    func embed(name: String) -> URL? {
        let roots = [documentDirectory] + (vaultRoot.map { [$0] } ?? [])
        if let direct = roots.lazy.compactMap({ self.existingFile($0.appending(path: name)) }).first
        {
            return direct
        }
        let suffix = "/" + name.lowercased()
        return
            vaultFiles
            .filter { $0.path(percentEncoded: false).lowercased().hasSuffix(suffix) }
            .min { $0.pathComponents.count < $1.pathComponents.count }
    }

    private func existingFile(_ url: URL) -> URL? {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue ? url : nil
    }

    private static func vaultRoot(containing directory: URL) -> URL? {
        var candidate = directory.standardizedFileURL
        while candidate.path(percentEncoded: false) != "/" {
            if FileManager.default.fileExists(
                atPath: candidate.appending(path: vaultMarker).path(percentEncoded: false))
            {
                return candidate
            }
            candidate = candidate.deletingLastPathComponent()
        }
        return nil
    }

    private static func files(under root: URL) -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        return enumerator?.compactMap { $0 as? URL } ?? []
    }
}
