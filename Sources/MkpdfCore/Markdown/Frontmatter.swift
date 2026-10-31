/// YAML frontmatter: a leading block between "---" and "---" (or "..."), as Obsidian and
/// static site generators write it. It is metadata, so it is not printed.
enum Frontmatter {
    private static let opening = "---"
    private static let closings: Set<Substring> = ["---", "..."]

    static func strip(_ text: String) -> String {
        // "\r\n" is one Character in Swift, so split on any newline, not on "\n".
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        guard let first = lines.first, trimmed(first) == opening else { return text }
        guard let closing = lines.dropFirst().firstIndex(where: { closings.contains(trimmed($0)) })
        else { return text }
        return lines[(closing + 1)...].joined(separator: "\n")
    }

    private static func trimmed(_ line: Substring) -> Substring {
        var line = line
        while line.last == " " {
            line = line.dropLast()
        }
        return line
    }
}
