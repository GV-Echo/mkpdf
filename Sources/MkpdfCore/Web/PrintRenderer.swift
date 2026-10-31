import AppKit
import WebKit

/// Loads a page into an off-screen web view, lets a script build its content, and prints
/// it to a paginated A4 PDF. `WKWebView.createPDF` is not used: it makes one tall page.
@MainActor
final class PrintRenderer: NSObject, WKNavigationDelegate {
    static let a4Size = NSSize(width: 595.28, height: 841.89)
    static let pageMargin: CGFloat = 50

    private let webView: WKWebView
    /// Printing needs the web view in a window; it is never shown.
    private let window: NSWindow
    private var navigation: CheckedContinuation<Void, any Error>?
    private var printing: CheckedContinuation<Bool, Never>?

    init(schemeHandler: WKURLSchemeHandler) {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: LocalSchemeHandler.scheme)
        let frame = NSRect(origin: .zero, size: Self.a4Size)
        webView = WKWebView(frame: frame, configuration: configuration)
        window = NSWindow(
            contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        super.init()
        window.contentView = webView
        webView.navigationDelegate = self
    }

    /// `script` is the body of an async function; its result is ignored, a thrown error
    /// fails the render.
    func render(page: URL, script: String, arguments: [String: Any], to output: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            navigation = continuation
            webView.load(URLRequest(url: page))
        }
        do {
            _ = try await webView.callAsyncJavaScript(
                script, arguments: arguments, in: nil, contentWorld: .page)
        } catch {
            throw ConversionError.rendering(Self.scriptMessage(of: error))
        }
        guard await print(to: output) else {
            throw ConversionError.rendering("printing to PDF failed")
        }
    }

    private func print(to output: URL) async -> Bool {
        let info = NSPrintInfo()
        info.paperSize = Self.a4Size
        info.topMargin = Self.pageMargin
        info.bottomMargin = Self.pageMargin
        info.leftMargin = Self.pageMargin
        info.rightMargin = Self.pageMargin
        info.jobDisposition = .save
        info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = output
        let operation = webView.printOperation(with: info)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        // Without a frame the operation prints blank pages.
        operation.view?.frame = webView.bounds
        return await withCheckedContinuation { continuation in
            printing = continuation
            operation.runModal(
                for: window,
                delegate: self,
                didRun: #selector(printOperationDidRun(_:success:contextInfo:)),
                contextInfo: nil
            )
        }
    }

    /// AppKit calls this on the print operation's own thread.
    @objc nonisolated private func printOperationDidRun(
        _ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?
    ) {
        Task { @MainActor in
            printing?.resume(returning: success)
            printing = nil
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.navigation?.resume()
        self.navigation = nil
    }

    func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error
    ) {
        failNavigation(error)
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        failNavigation(error)
    }

    private func failNavigation(_ error: any Error) {
        navigation?.resume(throwing: ConversionError.rendering(error.localizedDescription))
        navigation = nil
    }

    /// WebKit wraps a thrown JavaScript error; the message is the useful part.
    private static func scriptMessage(of error: any Error) -> String {
        let info = (error as NSError).userInfo
        return info["WKJavaScriptExceptionMessage"] as? String ?? error.localizedDescription
    }
}
