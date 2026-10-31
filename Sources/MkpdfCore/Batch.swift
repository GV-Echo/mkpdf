import Foundation

/// One file to convert: read `source`, write the PDF to `output`.
/// `output` is a scratch file in the source's folder; `Batch` renames it to the final name.
public struct ConversionJob: Sendable {
    public let source: URL
    public let output: URL
}

public protocol DocumentConverter {
    /// Returns one entry per job, in the same order: `nil` when the PDF was written.
    @MainActor func convert(_ jobs: [ConversionJob]) async -> [ConversionError?]
}

public struct FileReport: Sendable {
    public let source: URL
    /// The installed PDF, or why there is none.
    public let outcome: Result<URL, ConversionError>
}

/// Converts files by extension and installs each PDF next to its source with the same name.
/// A failure on one file never stops the others.
@MainActor
public struct Batch {
    private let convertersByExtension: [String: DocumentConverter]

    public init(convertersByExtension: [String: DocumentConverter]) {
        self.convertersByExtension = convertersByExtension
    }

    public func run(_ sources: [URL]) async -> [FileReport] {
        var reports: [URL: FileReport] = [:]
        var groups: [String: (converter: DocumentConverter, sources: [URL])] = [:]
        for source in sources {
            let fileExtension = source.pathExtension.lowercased()
            if let converter = convertersByExtension[fileExtension] {
                groups[fileExtension, default: (converter, [])].sources.append(source)
            } else {
                reports[source] = FileReport(
                    source: source, outcome: .failure(.unsupportedType(fileExtension)))
            }
        }
        for (_, group) in groups.sorted(by: { $0.key < $1.key }) {
            for report in await convert(group.sources, with: group.converter) {
                reports[report.source] = report
            }
        }
        return sources.compactMap { reports[$0] }
    }

    private func convert(_ sources: [URL], with converter: DocumentConverter) async -> [FileReport]
    {
        let jobs = sources.map { ConversionJob(source: $0, output: Self.scratchOutput(for: $0)) }
        let errors = await converter.convert(jobs)
        return zip(jobs, errors).map { job, error in
            let outcome: Result<URL, ConversionError>
            if let error {
                outcome = .failure(error)
            } else {
                do {
                    outcome = .success(try install(job.output, nextTo: job.source))
                } catch {
                    outcome = .failure(.fileSystem(error.localizedDescription))
                }
            }
            if case .failure = outcome {
                // Usually the converter wrote nothing and there is nothing to remove.
                try? FileManager.default.removeItem(at: job.output)
            }
            return FileReport(source: job.source, outcome: outcome)
        }
    }

    /// A hidden file next to the source, so installing is an atomic rename.
    private static func scratchOutput(for source: URL) -> URL {
        let stem = source.deletingPathExtension().lastPathComponent
        return source.deletingLastPathComponent().appending(
            path: ".\(stem).\(UUID().uuidString).pdf")
    }

    private func install(_ output: URL, nextTo source: URL) throws -> URL {
        let destination = Self.destination(for: source)
        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            _ = try FileManager.default.replaceItemAt(destination, withItemAt: output)
        } else {
            try FileManager.default.moveItem(at: output, to: destination)
        }
        return destination
    }

    /// Markdown through WebKit, docx and pptx through Word and PowerPoint.
    public static func standard() -> Batch {
        Batch(convertersByExtension: [
            "md": MarkdownConverter(),
            "docx": OfficeConverter(app: .word),
            "pptx": OfficeConverter(app: .powerPoint),
        ])
    }

    static func destination(for source: URL) -> URL {
        source.deletingPathExtension().appendingPathExtension("pdf")
    }
}
