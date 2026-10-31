import AppKit
import MkpdfCore

// Usage: mkpdf <file>... — writes <name>.pdf next to each file.

let usageExitCode: Int32 = 64

let paths = CommandLine.arguments.dropFirst()
if paths.isEmpty {
    FileHandle.standardError.write(Data("usage: mkpdf <file>...\n".utf8))
    exit(usageExitCode)
}
let sources = paths.map { URL(filePath: $0).standardizedFileURL }

// WebKit printing and Apple events need a running application, but no Dock icon or menu.
let application = NSApplication.shared
application.setActivationPolicy(.prohibited)

Task { @MainActor in
    let batch = Batch.standard()
    var failed = false
    for report in await batch.run(sources) {
        switch report.outcome {
        case .success(let pdf):
            print(pdf.path(percentEncoded: false))
        case .failure(let error):
            failed = true
            FileHandle.standardError.write(
                Data("\(report.source.lastPathComponent): \(error)\n".utf8))
        }
    }
    exit(failed ? EXIT_FAILURE : EXIT_SUCCESS)
}
application.run()
