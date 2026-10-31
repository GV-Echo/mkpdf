import Foundation
import Testing

@testable import MkpdfCore

/// Writes the source's bytes as the "PDF"; fails for sources whose name contains "fail".
private struct CopyingConverter: DocumentConverter {
    func convert(_ jobs: [ConversionJob]) async -> [ConversionError?] {
        jobs.map { job in
            if job.source.lastPathComponent.contains("fail") {
                return .rendering("asked to fail")
            }
            do {
                try FileManager.default.copyItem(at: job.source, to: job.output)
                return nil
            } catch {
                return .fileSystem(error.localizedDescription)
            }
        }
    }
}

@MainActor
@Suite struct BatchTests {
    let directory: URL
    let batch = Batch(convertersByExtension: ["txt": CopyingConverter()])

    init() throws {
        directory = try makeTemporaryDirectory()
    }

    private func makeFile(_ name: String, contents: String = "source") throws -> URL {
        let url = directory.appending(path: name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func writesPDFNextToSourceWithSameName() async throws {
        let source = try makeFile("Отчёт за год.txt", contents: "body")
        let reports = await batch.run([source])
        let pdf = directory.appending(path: "Отчёт за год.pdf")
        #expect(try reports.first?.outcome.get() == pdf)
        #expect(try String(contentsOf: pdf, encoding: .utf8) == "body")
    }

    @Test func replacesExistingPDF() async throws {
        let source = try makeFile("Моя заметка.txt", contents: "new")
        _ = try makeFile("Моя заметка.pdf", contents: "old")
        let reports = await batch.run([source])
        #expect((try? reports[0].outcome.get()) != nil)
        let pdf = directory.appending(path: "Моя заметка.pdf")
        #expect(try String(contentsOf: pdf, encoding: .utf8) == "new")
    }

    @Test func failureOnOneFileKeepsTheRestAndOrder() async throws {
        let sources = [
            try makeFile("a.txt"), try makeFile("b-fail.txt"), try makeFile("c.unknown"),
            try makeFile("d.TXT"),
        ]
        let reports = await batch.run(sources)
        #expect(reports.map(\.source) == sources)
        #expect((try? reports[0].outcome.get()) != nil)
        #expect((try? reports[1].outcome.get()) == nil)
        #expect("\(failure(of: reports[2]))" == "\".unknown\" files are not supported")
        #expect((try? reports[3].outcome.get()) != nil)
        #expect(
            !FileManager.default.fileExists(
                atPath: directory.appending(path: "b-fail.pdf").path(percentEncoded: false)))
    }

    private func failure(of report: FileReport) -> String {
        guard case .failure(let error) = report.outcome else { return "success" }
        return error.description
    }
}
