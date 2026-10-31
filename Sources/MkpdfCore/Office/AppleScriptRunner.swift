import Foundation

/// Runs AppleScript in-process and turns its errors into messages a user can act on.
enum AppleScriptRunner {
    struct Failure: Error {
        let code: Int
        let message: String
    }

    /// Apple event error codes that need their own explanation.
    enum Code {
        static let userCanceled = -128
        static let notAllowed = -1743
        static let timedOut = -1712
    }

    @MainActor @discardableResult
    static func run(_ source: String) throws(Failure) -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else {
            throw Failure(code: 0, message: "could not create the script")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw Failure(
                code: errorInfo[NSAppleScript.errorNumber] as? Int ?? 0,
                message: errorInfo[NSAppleScript.errorMessage] as? String ?? "unknown error"
            )
        }
        return result
    }

    /// A string literal with quotes and backslashes escaped.
    static func literal(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    static func strings(in descriptor: NSAppleEventDescriptor) -> [String] {
        guard descriptor.numberOfItems > 0 else { return [] }
        return (1...descriptor.numberOfItems).compactMap { descriptor.atIndex($0)?.stringValue }
    }
}
