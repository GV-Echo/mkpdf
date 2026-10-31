/// The parts of Word's and PowerPoint's AppleScript dictionaries that mkpdf uses.
public enum OfficeApp: Sendable {
    case word
    case powerPoint

    var bundleIdentifier: String {
        switch self {
        case .word: "com.microsoft.Word"
        case .powerPoint: "com.microsoft.Powerpoint"
        }
    }

    var displayName: String {
        switch self {
        case .word: "Microsoft Word"
        case .powerPoint: "Microsoft PowerPoint"
        }
    }

    var documentClass: String {
        switch self {
        case .word: "document"
        case .powerPoint: "presentation"
        }
    }

    /// The property holding a document's POSIX path.
    var pathProperty: String {
        switch self {
        case .word: "posix full name"
        case .powerPoint: "full name"
        }
    }

    /// `document` must be an index reference: both apps reject a `whose` reference here.
    func savePDF(document: String, to output: String) -> String {
        switch self {
        case .word:
            "save as \(document) file name \(output) file format format PDF"
        case .powerPoint:
            "save \(document) in (POSIX file \(output)) as save as PDF"
        }
    }
}
