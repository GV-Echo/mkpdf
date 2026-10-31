import Foundation

public enum ConversionError: Error, CustomStringConvertible, Sendable {
    case unsupportedType(String)
    case fileSystem(String)
    case rendering(String)
    case office(String)

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
        }
    }
}
