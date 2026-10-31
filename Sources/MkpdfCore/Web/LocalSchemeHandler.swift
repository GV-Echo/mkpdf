import Foundation
import WebKit

/// Serves `mkpdf://` URLs to the page:
/// - `mkpdf://asset/<path>`: embedded assets;
/// - `mkpdf://image/?ref=<path>`: a Markdown image path, relative to the note;
/// - `mkpdf://embed/?name=<name>`: an Obsidian `![[name]]` embed.
/// The prefixes must match `render.js`.
@MainActor
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "mkpdf"

    private enum Route: String {
        case asset
        case image
        case embed
    }

    private let resolver: ResourceResolver

    init(resolver: ResourceResolver) {
        self.resolver = resolver
    }

    static func assetURL(_ path: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = Route.asset.rawValue
        components.path = "/\(path)"
        guard let url = components.url else {
            preconditionFailure("asset path \(path) does not form a URL")
        }
        return url
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let (data, mimeType) = content(for: url) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        task.didReceive(
            URLResponse(
                url: url, mimeType: mimeType, expectedContentLength: data.count,
                textEncodingName: nil))
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}

    func content(for url: URL) -> (Data, String)? {
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let file: URL?
        switch url.host().flatMap(Route.init(rawValue:)) {
        case .asset:
            return EmbeddedAssets.asset(at: String(url.path(percentEncoded: false).dropFirst())).map
            {
                ($0.data, $0.mimeType)
            }
        case .image:
            file = query?.first { $0.name == "ref" }?.value.flatMap(resolver.image(reference:))
        case .embed:
            file = query?.first { $0.name == "name" }?.value.flatMap(resolver.embed(name:))
        case nil:
            file = nil
        }
        guard let file, let data = try? Data(contentsOf: file) else { return nil }
        return (data, EmbeddedAssets.mimeType(forPath: file.path(percentEncoded: false)))
    }
}
