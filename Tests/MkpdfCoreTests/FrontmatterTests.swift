import Testing

@testable import MkpdfCore

struct FrontmatterTests {
    @Test func removesLeadingBlock() {
        #expect(Frontmatter.strip("---\ntitle: x\n---\n# Body\n") == "# Body\n")
    }

    @Test func acceptsDotsAndWindowsLineEndings() {
        #expect(Frontmatter.strip("---\r\ntitle: x\r\n...\r\nBody") == "Body")
    }

    @Test func keepsTextWithoutLeadingBlock() {
        let text = "# Title\n\n---\n\nAfter a rule\n---\n"
        #expect(Frontmatter.strip(text) == text)
    }

    @Test func keepsUnclosedBlock() {
        let text = "---\nnot closed\n# Body"
        #expect(Frontmatter.strip(text) == text)
    }
}
