import Foundation

enum CodeLanguageDetector {
    struct Detection {
        let language: String
    }

    static func detect(_ text: String) -> Detection? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 20 else { return nil }

        if isSQL(trimmed) { return Detection(language: "SQL") }
        if isTypeScript(trimmed) { return Detection(language: "TypeScript") }
        if isPython(trimmed) { return Detection(language: "Python") }
        if isShell(trimmed) { return Detection(language: "Shell") }
        if isJSON(trimmed) { return Detection(language: "JSON") }
        if isSwift(trimmed) { return Detection(language: "Swift") }
        if isHTML(trimmed) { return Detection(language: "HTML") }
        if isCSS(trimmed) { return Detection(language: "CSS") }
        if isGo(trimmed) { return Detection(language: "Go") }
        if isRust(trimmed) { return Detection(language: "Rust") }
        if isJava(trimmed) { return Detection(language: "Java") }
        if isCSharp(trimmed) { return Detection(language: "C#") }

        return nil
    }

    private static func isSQL(_ t: String) -> Bool {
        let lower = t.lowercased()
        let keywords = ["select ", "from ", "where ", "insert into", "create table", "alter table", "join ", "group by", "order by", "having ", "union "]
        return keywords.filter { lower.contains($0) }.count >= 2
    }

    private static func isTypeScript(_ t: String) -> Bool {
        let patterns = [": string", ": number", ": boolean", "interface ", "=> {", "const ", "let ", ": void", "as ", "export "]
        return patterns.filter { t.contains($0) }.count >= 3
    }

    private static func isPython(_ t: String) -> Bool {
        let patterns = ["def ", "import ", "from ", "class ", "if __name__", "self.", "print(", "elif ", "range("]
        return patterns.filter { t.contains($0) }.count >= 2
    }

    private static func isShell(_ t: String) -> Bool {
        let patterns = ["#!/bin/bash", "#!/bin/sh", "#!/bin/zsh", "$(", " | grep", "echo ", "export ", "chmod "]
        return patterns.filter { t.contains($0) }.count >= 2
    }

    private static func isJSON(_ t: String) -> Bool {
        let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
              (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) else { return false }
        return (trimmed.contains("\":") || trimmed.contains("\" :")) && trimmed.contains("\"")
    }

    private static func isSwift(_ t: String) -> Bool {
        let patterns = ["func ", "var ", "let ", "guard ", "struct ", "class ", "import UIKit", "import SwiftUI", "import AppKit", "-> ", ".self"]
        return patterns.filter { t.contains($0) }.count >= 3
    }

    private static func isHTML(_ t: String) -> Bool {
        let lower = t.lowercased()
        let patterns = ["<html", "<div", "<span", "<head", "<body", "<!doctype", "</"]
        return patterns.filter { lower.contains($0) }.count >= 3
    }

    private static func isCSS(_ t: String) -> Bool {
        let patterns = ["{", "}", ":", ";", "margin", "padding", "display", "color:", "background"]
        return patterns.filter { t.contains($0) }.count >= 4 && t.contains("{") && t.contains("}")
    }

    private static func isGo(_ t: String) -> Bool {
        let patterns = ["func ", "package ", "import (", ":=", "fmt.", "err != nil", "go func"]
        return patterns.filter { t.contains($0) }.count >= 3
    }

    private static func isRust(_ t: String) -> Bool {
        let patterns = ["fn ", "let mut", "impl ", "pub fn", "-> ", "use ", "::", "match "]
        return patterns.filter { t.contains($0) }.count >= 3
    }

    private static func isJava(_ t: String) -> Bool {
        let patterns = ["public class", "private ", "protected ", "void ", "System.out", "new ", "import java"]
        return patterns.filter { t.contains($0) }.count >= 3
    }

    private static func isCSharp(_ t: String) -> Bool {
        let patterns = ["using ", "namespace ", "public class", "var ", "void ", "Console."]
        return patterns.filter { t.contains($0) }.count >= 3
    }
}
