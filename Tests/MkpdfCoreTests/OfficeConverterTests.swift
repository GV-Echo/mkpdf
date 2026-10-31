import AppKit
import Foundation
import Testing

@testable import MkpdfCore

/// These launch Word and PowerPoint, so they run only with MKPDF_OFFICE_TESTS=1.
private let officeTestsEnabled = ProcessInfo.processInfo.environment["MKPDF_OFFICE_TESTS"] == "1"

@MainActor
@Suite(.enabled(if: officeTestsEnabled), .serialized)
struct OfficeConverterTests {
    let directory: URL

    init() throws {
        directory = try makeTemporaryDirectory()
    }

    private func isRunning(_ app: OfficeApp) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
            .isEmpty
    }

    @Test func convertsDocxAndPptxAndQuitsAppsItStarted() async throws {
        try #require(!isRunning(.word) && !isRunning(.powerPoint), "close Word and PowerPoint")
        let document = try copyFixture("document.docx", to: directory)
        let slides = try copyFixture("slides.pptx", to: directory)

        let reports = await Batch.standard().run([document, slides])

        let documentPDF = try summarizePDF(at: try reports[0].outcome.get())
        #expect(documentPDF.text.contains("Word fixture heading"))
        #expect(documentPDF.text.contains("Кириллица в документе"))
        let slidesPDF = try summarizePDF(at: try reports[1].outcome.get())
        #expect(slidesPDF.pageCount == 2)
        #expect(slidesPDF.text.contains("Слайд два"))
        #expect(!isRunning(.word) && !isRunning(.powerPoint))
    }

    @Test func leavesTheUsersOpenDocumentAndRunningAppAlone() async throws {
        // Short names: Word names a lock file "~$<name>" only for short names.
        let usersDocument = directory.appending(path: "mine.docx")
        let otherDocument = directory.appending(path: "temp.docx")
        let fixture = try copyFixture("document.docx", to: directory)
        try FileManager.default.copyItem(at: fixture, to: usersDocument)
        try FileManager.default.copyItem(at: fixture, to: otherDocument)
        try openInWord(usersDocument.path(percentEncoded: false))

        let reports = await Batch.standard().run([usersDocument, otherDocument])

        #expect(reports.allSatisfy { (try? $0.outcome.get()) != nil })
        #expect(isRunning(.word))
        // Word sometimes stops reporting the remaining document's path to AppleScript after
        // another document closes, so check what is open by count and lock files instead.
        let count = try AppleScriptRunner.run(
            "tell application id \"\(OfficeApp.word.bundleIdentifier)\" to count documents")
        #expect(count.int32Value == 1)
        #expect(lockFileExists(for: "mine.docx"))
        #expect(!lockFileExists(for: "temp.docx"))
        try AppleScriptRunner.run(
            """
            tell application id "\(OfficeApp.word.bundleIdentifier)"
            close every document saving no
            quit saving no
            end tell
            """)
    }

    private func lockFileExists(for name: String) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appending(path: "~$\(name)").path(percentEncoded: false))
    }

    private func openInWord(_ path: String) throws {
        let open = """
            tell application id "\(OfficeApp.word.bundleIdentifier)" to open (POSIX file \
            \(AppleScriptRunner.literal(path)))
            """
        let word = try #require(
            NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: OfficeApp.word.bundleIdentifier))
        NSWorkspace.shared.openApplication(
            at: word, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        let deadline = Date.now.addingTimeInterval(60)
        while (try? wordDocumentPaths().contains(path)) != true {
            try #require(Date.now < deadline, "Word did not open the document")
            _ = try? AppleScriptRunner.run(open)
            RunLoop.main.run(until: .now.addingTimeInterval(2))
        }
    }

    private func wordDocumentPaths() throws -> [String] {
        let paths = try AppleScriptRunner.run(
            "tell application id \"\(OfficeApp.word.bundleIdentifier)\" to get "
                + "posix full name of every document")
        return AppleScriptRunner.strings(in: paths)
    }
}
