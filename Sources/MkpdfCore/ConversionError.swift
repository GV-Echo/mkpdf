import Foundation

public enum ConversionError: Error, CustomStringConvertible, Sendable {
    case unsupportedType(String)
    case fileSystem(String)
    case rendering(String)
    case office(String)
    case sameOutput(String)
    case readOnlyFolder(String)
    case notUTF8

    public var description: String {
        switch self {
        case .unsupportedType(let fileExtension):
            fileExtension.isEmpty
                ? "files without an extension are not supported"
                : "\".\(fileExtension)\" files are not supported"
        case .fileSystem(let reason):
            reason
        case .rendering(let reason):
            "rendering failed: \(reason)"
        case .office(let reason):
            reason
        case .sameOutput(let pdfName):
            "another selected file also becomes \"\(pdfName)\""
        case .readOnlyFolder(let folderName):
            "cannot write to the folder \"\(folderName)\""
        case .notUTF8:
            "the file is not UTF-8 text"
        }
    }
}
