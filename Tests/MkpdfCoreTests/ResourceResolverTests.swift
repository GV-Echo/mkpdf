import Foundation
import Testing

@testable import MkpdfCore

@MainActor
@Suite struct ResourceResolverTests {
    let vault: URL
    let resolver: ResourceResolver

    init() throws {
        vault = try copyFixture("vault", to: try makeTemporaryDirectory())
        resolver = ResourceResolver(document: vault.appending(path: "notes/features.md"))
    }

    @Test func resolvesRelativeAndPercentEncodedImagePaths() {
        #expect(resolver.image(reference: "blue.png")?.lastPathComponent == "blue.png")
        #expect(
            resolver.image(reference: "../attachments/red%20square.png")?.lastPathComponent
                == "red square.png")
        #expect(resolver.image(reference: "missing.png") == nil)
    }

    @Test func findsEmbedsAnywhereInTheVault() {
        #expect(resolver.embed(name: "red square.png")?.lastPathComponent == "red square.png")
        #expect(resolver.embed(name: "attachments/red square.png") != nil)
        #expect(resolver.embed(name: "RED SQUARE.png") != nil)
        #expect(resolver.embed(name: "missing.png") == nil)
    }

    @Test func outsideAVaultEmbedsResolveOnlyNextToTheNote() throws {
        let directory = try makeTemporaryDirectory()
        let image = directory.appending(path: "picture.png")
        try Data([0]).write(to: image)
        try FileManager.default.createDirectory(
            at: directory.appending(path: "nested"), withIntermediateDirectories: true)
        try Data([0]).write(to: directory.appending(path: "nested/deep.png"))
        let loose = ResourceResolver(document: directory.appending(path: "note.md"))
        #expect(loose.embed(name: "picture.png") != nil)
        #expect(loose.embed(name: "deep.png") == nil)
    }

    @Test func schemeHandlerServesImagesAndAssets() throws {
        let handler = LocalSchemeHandler(resolver: resolver)
        let image = try #require(URL(string: "mkpdf://embed/?name=red%20square.png"))
        #expect(handler.content(for: image)?.1 == "image/png")
        let asset = LocalSchemeHandler.assetURL("src/render.js")
        #expect(handler.content(for: asset)?.1 == "text/javascript")
        let missing = try #require(URL(string: "mkpdf://image/?ref=nothing.png"))
        #expect(handler.content(for: missing) == nil)
    }
}
