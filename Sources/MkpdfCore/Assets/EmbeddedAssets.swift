import Foundation
import UniformTypeIdentifiers

/// Files from `Assets/`, compiled into the binary by the AssetPacker build plugin.
enum EmbeddedAssets {
    struct Asset {
        let data: Data
        let mimeType: String
    }

    /// `path` is relative to `Assets/`, for example `vendor/katex.min.js`.
    static func asset(at path: String) -> Asset? {
        guard let base64 = GeneratedAssets.base64ByPath[path],
            let data = Data(base64Encoded: base64)
        else { return nil }
        return Asset(data: data, mimeType: mimeType(forPath: path))
    }

    static func mimeType(forPath path: String) -> String {
        let pathExtension = (path as NSString).pathExtension
        return UTType(filenameExtension: pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
    }
}
