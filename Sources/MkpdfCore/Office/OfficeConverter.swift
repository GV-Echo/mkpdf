import AppKit

/// docx / pptx → PDF by asking Word / PowerPoint to save the document as PDF.
///
/// The app is launched once per batch and quit at the end only if it was not running
/// before. Documents the user already had open are exported but left open; documents
/// mkpdf opened are closed without saving.
///
/// Office is sandboxed: it asks the user for access to every new folder it writes to, but
/// remembers a folder once granted. So it always saves into one exchange folder, granted
/// once per app, and mkpdf moves the PDF next to the source. Office's own containers would
/// need no grant, but reading them needs a macOS permission that is asked on every run for
/// an app without a Developer ID.
@MainActor
public struct OfficeConverter: DocumentConverter {
    private static let readyTimeout: Duration = .seconds(60)
    /// The next run must not find the app still shutting down and take it for running.
    private static let quitTimeout: Duration = .seconds(30)
    private static let openTimeout: Duration = .seconds(30)
    private static let pollInterval: Duration = .milliseconds(500)
    /// An `open` sent while the app is still starting can be dropped; it is sent again.
    private static let reopenInterval: Duration = .seconds(5)
    /// Long enough for a big presentation, or for the user to answer Office's one-time
    /// access dialog for the exchange folder.
    private static let saveTimeoutSeconds = 600
    /// Fixed: a grant covers only this folder, not its subfolders.
    private static let exchangeFolder = "Library/Application Support/mkpdf/Office"

    private let app: OfficeApp

    public init(app: OfficeApp) {
        self.app = app
    }

    public func convert(_ jobs: [ConversionJob]) async -> [ConversionError?] {
        guard
            let appURL = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: app.bundleIdentifier)
        else {
            return jobs.map { _ in .office("\(app.displayName) is not installed") }
        }
        let exchange = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: Self.exchangeFolder, directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(
                at: exchange, withIntermediateDirectories: true)
        } catch {
            let reason = error.localizedDescription
            return jobs.map { _ in .office(reason) }
        }
        let wasRunning = isRunning
        let alreadyOpen: Set<String>
        do {
            if !wasRunning {
                try await launch(appURL)
            }
            alreadyOpen = try openDocumentPaths()
        } catch {
            let reason = describe(error)
            return jobs.map { _ in .office(reason) }
        }
        var errors: [ConversionError?] = []
        for job in jobs {
            errors.append(
                await export(
                    job, via: exchange, keepOpen: alreadyOpen.contains(path(of: job.source))))
        }
        if !wasRunning {
            // The PDFs are written; failing to quit leaves the app open, nothing more.
            _ = try? AppleScriptRunner.run(tell("quit saving no"))
            _ = try? await poll(timeout: Self.quitTimeout, failure: "did not quit") {
                !isRunning
            }
        }
        return errors
    }

    private func export(
        _ job: ConversionJob, via exchange: URL, keepOpen: Bool
    ) async -> ConversionError? {
        let source = path(of: job.source)
        let saved = exchange.appending(path: "\(UUID().uuidString).pdf")
        do {
            if !keepOpen {
                try await open(source)
            }
            let document = "\(app.documentClass) target"
            // By path, not by index: the index follows window order, which can change between
            // the lookup and the close.
            let close =
                keepOpen
                ? ""
                : "close (every \(app.documentClass) whose \(app.pathProperty) is "
                    + "\(AppleScriptRunner.literal(source))) saving no"
            try AppleScriptRunner.run(
                """
                with timeout of \(Self.saveTimeoutSeconds) seconds
                \(tell(
                    """
                    set target to missing value
                    repeat with i from 1 to count of \(app.documentClass)s
                        if \(app.pathProperty) of \(app.documentClass) i is \
                    \(AppleScriptRunner.literal(source)) then set target to i
                    end repeat
                    \(app.savePDF(document: document, to: AppleScriptRunner.literal(path(of: saved))))
                    \(close)
                    """))
                end timeout
                """)
        } catch {
            return .office(describe(error))
        }
        guard FileManager.default.fileExists(atPath: path(of: saved)) else {
            return .office("\(app.displayName) finished without writing the PDF")
        }
        do {
            try FileManager.default.moveItem(at: saved, to: job.output)
        } catch {
            return .fileSystem(error.localizedDescription)
        }
        return nil
    }

    private var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
            .isEmpty
    }

    private func launch(_ appURL: URL) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, any Error>) in
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) {
                @Sendable
                _, error in  // Called on a LaunchServices queue.
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        // The app answers Apple events only some time after it is launched.
        try await poll(timeout: Self.readyTimeout, failure: "did not start in time") {
            do {
                _ = try openDocumentPaths()
                return true
            } catch let failure as AppleScriptRunner.Failure
                where failure.code == AppleScriptRunner.Code.notAllowed
            {
                throw failure
            } catch {
                return false
            }
        }
    }

    private func open(_ source: String) async throws {
        let openCommand = tell("open (POSIX file \(AppleScriptRunner.literal(source)))")
        var lastOpen = ContinuousClock.now
        try AppleScriptRunner.run(openCommand)
        try await poll(timeout: Self.openTimeout, failure: "did not open the file in time") {
            if try openDocumentPaths().contains(source) {
                return true
            }
            if ContinuousClock.now - lastOpen > Self.reopenInterval {
                try AppleScriptRunner.run(openCommand)
                lastOpen = .now
            }
            return false
        }
    }

    private func openDocumentPaths() throws(AppleScriptRunner.Failure) -> Set<String> {
        let paths = try AppleScriptRunner.run(
            tell("get \(app.pathProperty) of every \(app.documentClass)"))
        return Set(AppleScriptRunner.strings(in: paths))
    }

    private func poll(
        timeout: Duration, failure: String, until isDone: () throws -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while try !isDone() {
            guard ContinuousClock.now < deadline else {
                throw AppleScriptRunner.Failure(code: 0, message: failure)
            }
            try await Task.sleep(for: Self.pollInterval)
        }
    }

    private func tell(_ body: String) -> String {
        "tell application id \(AppleScriptRunner.literal(app.bundleIdentifier))\n\(body)\nend tell"
    }

    private func path(of url: URL) -> String {
        url.path(percentEncoded: false)
    }

    private func describe(_ error: any Error) -> String {
        guard let failure = error as? AppleScriptRunner.Failure else {
            return error.localizedDescription
        }
        switch failure.code {
        case AppleScriptRunner.Code.notAllowed:
            return "not allowed to control \(app.displayName): allow it in System Settings → "
                + "Privacy & Security → Automation"
        case AppleScriptRunner.Code.userCanceled:
            return "\(app.displayName) was not given access to mkpdf's exchange folder; "
                + "run again and grant it"
        case AppleScriptRunner.Code.timedOut:
            return "\(app.displayName) did not respond in time; it may be waiting in a dialog, "
                + "for example for a password"
        default:
            return "\(app.displayName): \(failure.message)"
        }
    }
}
