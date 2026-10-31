import Foundation
import Testing

@testable import MkpdfCore

@MainActor
@Suite struct MarkdownConverterTests {
    let directory: URL
    let batch = Batch(convertersByExtension: ["md": MarkdownConverter()])

    init() throws {
        directory = try makeTemporaryDirectory()
    }

    private func convertFixture(_ name: String) async throws -> PDFSummary {
        let source = try copyFixture(name, to: directory)
        let report = try #require(await batch.run([source]).first)
        return try summarizePDF(at: try report.outcome.get())
    }

    @Test func longDocumentIsSplitIntoA4Pages() async throws {
        let pdf = try await convertFixture("long.md")
        #expect(pdf.pageCount > 1)
        #expect(abs(pdf.pageSize.width - PrintRenderer.a4Size.width) < 1)
        #expect(abs(pdf.pageSize.height - PrintRenderer.a4Size.height) < 1)
        #expect(pdf.text.contains("Раздел 1"))
        #expect(pdf.text.contains("Last paragraph"))
    }

    @Test func extendedSyntaxIsRendered() async throws {
        let vault = try copyFixture("vault", to: directory)
        let source = vault.appending(path: "notes/features.md")
        let report = try #require(await batch.run([source]).first)
        let text = try summarizePDF(at: try report.outcome.get()).text
        for expected in [
            "Open task", "Footnote body text", "let greeting", "Obsidian title",
            "Obsidian callout body", "Warning", "GitHub warning body",
            "See Other note and alias text",
            "costs $5 and $10", "Start", "Finish",
        ] {
            #expect(text.contains(expected), "missing \(expected)")
        }
        for raw in [
            "[ ]", "[x]", "[^1]", "```", "[!note]", "[!WARNING]", "[[", "$$", "mermaid",
            "flowchart", "Hidden frontmatter title", "secret-tag",
        ] {
            #expect(!text.contains(raw), "raw markup \(raw)")
        }
    }

    @Test func nonUTF8FileIsReportedAsSuch() async throws {
        let source = directory.appending(path: "cp1251.md")
        try #require("# Заголовок".data(using: .windowsCP1251)).write(to: source)
        let report = try #require(await batch.run([source]).first)
        guard case .failure(let error) = report.outcome else {
            Issue.record("converted a non-UTF-8 file")
            return
        }
        #expect(error.description == "the file is not UTF-8 text")
    }

    @Test func basicMarkdownIsRenderedNotPrintedRaw() async throws {
        let pdf = try await convertFixture("basic.md")
        #expect(pdf.text.contains("Bold text and inline code"))
        #expect(pdf.text.contains("Cell B2"))
        #expect(!pdf.text.contains("**"))
        #expect(!pdf.text.contains("|---"))
    }
}
