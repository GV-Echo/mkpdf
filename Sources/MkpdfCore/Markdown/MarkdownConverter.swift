import Foundation

/// Markdown → HTML (markdown-it in the page) → PDF through WebKit's print path.
@MainActor
public struct MarkdownConverter: DocumentConverter {
    private static let page = LocalSchemeHandler.assetURL("src/page.html")
    private static let renderScript = "await mkpdfRender(source)"

    public init() {}

    public func convert(_ jobs: [ConversionJob]) async -> [ConversionError?] {
        var errors: [ConversionError?] = []
        for job in jobs {
            errors.append(await convert(job))
        }
        return errors
    }

    private func convert(_ job: ConversionJob) async -> ConversionError? {
        let bytes: Data
        do {
            bytes = try Data(contentsOf: job.source)
        } catch {
            return .fileSystem(error.localizedDescription)
        }
        guard let source = String(data: bytes, encoding: .utf8) else {
            return .notUTF8
        }
        let resolver = ResourceResolver(document: job.source)
        let renderer = PrintRenderer(schemeHandler: LocalSchemeHandler(resolver: resolver))
        do {
            try await renderer.render(
                page: Self.page, script: Self.renderScript,
                arguments: ["source": Frontmatter.strip(source)],
                to: job.output)
        } catch let error as ConversionError {
            return error
        } catch {
            return .rendering(error.localizedDescription)
        }
        return nil
    }
}
