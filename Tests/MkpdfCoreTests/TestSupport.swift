import Foundation
import PDFKit
import Testing

/// A fresh directory per test; tests never write next to real files.
func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "mkpdf-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

/// Copies `Fixtures/<name>` (a file or a folder) into `directory`.
func copyFixture(_ name: String, to directory: URL) throws -> URL {
    let fixtures = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
    let destination = directory.appending(path: name)
    try FileManager.default.copyItem(at: fixtures.appending(path: name), to: destination)
    return destination
}

struct PDFSummary {
    let pageCount: Int
    let pageSize: CGSize
    /// All pages' text, whitespace collapsed to single spaces.
    let text: String
}

func summarizePDF(at url: URL) throws -> PDFSummary {
    let document = try #require(PDFDocument(url: url))
    let firstPage = try #require(document.page(at: 0))
    let text = (0..<document.pageCount)
        .compactMap { document.page(at: $0)?.string }
        .joined(separator: " ")
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
    return PDFSummary(
        pageCount: document.pageCount,
        pageSize: firstPage.bounds(for: .mediaBox).size,
        text: text
    )
}
