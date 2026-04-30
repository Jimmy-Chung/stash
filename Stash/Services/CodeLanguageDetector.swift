import Foundation

enum CodeLanguageDetector {
    static func isCode(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 20 else { return false }

        let lower = trimmed.lowercased()

        let patterns = [
            // SQL
            "select ", "from ", "where ", "insert into", "create table", "alter table",
            "join ", "group by", "order by", "having ", "union ",
            // TypeScript
            ": string", ": number", ": boolean", "interface ", "=> {", ": void", "as ", "export ",
            // Python
            "def ", "import ", "if __name__", "self.", "print(", "elif ", "range(",
            // Shell
            "#!/bin/bash", "#!/bin/sh", "#!/bin/zsh", "$(", " | grep", "echo ", "chmod ",
            // Swift
            "func ", "guard ", "struct ", "import uikit", "import swiftui", "import appkit", ".self",
            // HTML
            "<html", "<div", "<span", "<head", "<body", "<!doctype", "</",
            // CSS
            "font-size", "font-family", "font-weight", "background-color",
            "border-radius", "box-shadow", "text-align", "max-width",
            "grid-template", "flex-direction", "@media", "@keyframes",
            // Go
            "package ", "import (", "fmt.", "err != nil", "go func",
            // Rust
            "fn ", "let mut", "impl ", "pub fn", "match ",
            // Java
            "public class", "private ", "protected ", "void ", "system.out", "import java",
            // C#
            "namespace ", "console.",
            // Generic
            "const ", "let ", "var ", "class ", "-> ", "::",
        ]

        let matchCount = patterns.filter { lower.contains($0) }.count
        guard matchCount >= 3 else { return false }

        return true
    }
}
