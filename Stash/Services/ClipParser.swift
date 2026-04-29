import AppKit

struct ParsedClip {
    let type: ClipType
    let textContent: String?
    let imageData: Data?
    var title: String?
    var colorHex: String?
    var colorRGB: String?
    var codeLanguage: String?
    var fileName: String?
    var imageWidth: Int?
    var imageHeight: Int?
    var dominantColors: [String]?

    var hashData: Data {
        switch type {
        case .text, .link, .code, .color, .rtf:
            return Data((textContent ?? "").utf8)
        case .image:
            return imageData ?? Data()
        case .file:
            return Data((textContent ?? "").utf8)
        }
    }
}

enum ClipParser {
    static func parse(_ pasteboard: NSPasteboard) -> ParsedClip? {
        // 1. File URL — MUST check before image data.
        //    Finder puts file icons as TIFF on the clipboard, so if we check
        //    image data first, file copies get misclassified as images.
        let resolvedFileURL: URL? = {
            // Try public.file-url (Finder uses this for all file copies)
            if let s = pasteboard.string(forType: .fileURL) {
                if let url = URL(string: s) {
                    // Resolve file reference URLs (file:///.file/id=...)
                    if let resolved = (url as NSURL).filePathURL {
                        return resolved
                    }
                    // Already a path-based file URL
                    if url.isFileURL { return url }
                }
            }
            // Try public.url as fallback
            if let s = pasteboard.string(forType: .URL),
               s.hasPrefix("file://"),
               let url = URL(string: s) {
                if let resolved = (url as NSURL).filePathURL { return resolved }
                return url
            }
            // Try NSFilenamesPboardType (deprecated but some apps still use it)
            if let paths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("com.apple.NSFilenamesPboardType")) as? [String],
               let first = paths.first {
                return URL(fileURLWithPath: first)
            }
            return nil
        }()

        if let url = resolvedFileURL {
            let ext = url.pathExtension.lowercased()
            let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif"]

            // If it's an image file, read data and classify as image
            if imageExtensions.contains(ext),
               let data = try? Data(contentsOf: url) {
                var clip = ParsedClip(type: .image, textContent: nil, imageData: data)
                if let meta = ImageMetadataService.extract(from: data) {
                    clip.imageWidth = meta.width
                    clip.imageHeight = meta.height
                    clip.dominantColors = meta.dominantColors
                }
                return clip
            }

            // Otherwise classify as generic file
            let path = url.path
            let fileName = url.deletingPathExtension().lastPathComponent
            let extUpper = url.pathExtension.uppercased()
            let title = extUpper.isEmpty ? fileName : "\(fileName).\(extUpper)"
            return ParsedClip(type: .file, textContent: path, imageData: nil, fileName: title)
        }

        // 2. Image data (PNG, TIFF) — only reached if no file URL was found.
        //    This handles images copied from image editors, screenshots, etc.
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            var clip = ParsedClip(type: .image, textContent: nil, imageData: data)
            if let meta = ImageMetadataService.extract(from: data) {
                clip.imageWidth = meta.width
                clip.imageHeight = meta.height
                clip.dominantColors = meta.dominantColors
            }
            return clip
        }

        // 3. RTF data
        if let data = pasteboard.data(forType: .rtf) {
            let attrString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            let text = attrString?.string ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if let special = detectSpecialType(trimmed) { return special }
            return ParsedClip(type: .rtf, textContent: text, imageData: nil)
        }

        // 4. HTML data — split by what the user actually copied.
        //    If the user-visible string has HTML tags they intended to keep
        //    raw markup (treat as Code/HTML); otherwise it's rich text from a
        //    web page or doc and the stripped text is what they want (Text).
        if let data = pasteboard.data(forType: .html) {
            let html = String(data: data, encoding: .utf8) ?? ""
            let visible = pasteboard.string(forType: .string) ?? stripHTMLTags(html)
            let trimmed = visible.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if let special = detectSpecialType(trimmed) { return special }
            if containsHTMLTags(trimmed) {
                return ParsedClip(type: .code, textContent: visible, imageData: nil, codeLanguage: "HTML")
            }
            return ParsedClip(type: .text, textContent: visible, imageData: nil)
        }

        // 5. URL string
        if let urlString = pasteboard.string(forType: .URL),
           !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           urlString.hasPrefix("http") {
            return ParsedClip(type: .link, textContent: urlString.trimmingCharacters(in: .whitespacesAndNewlines), imageData: nil)
        }

        // 6. String content - detect subtypes
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let special = detectSpecialType(trimmed) { return special }
            return ParsedClip(type: .text, textContent: text, imageData: nil)
        }

        return nil
    }

    private static func detectSpecialType(_ trimmed: String) -> ParsedClip? {
        // URL
        if let url = URL(string: trimmed),
           let scheme = url.scheme,
           (scheme == "http" || scheme == "https"),
           url.host != nil {
            return ParsedClip(type: .link, textContent: trimmed, imageData: nil)
        }
        // Color
        if let color = ColorParser.parse(trimmed) {
            return ParsedClip(type: .color, textContent: trimmed, imageData: nil, colorHex: color.hex, colorRGB: color.rgb)
        }
        // Code
        if let detection = CodeLanguageDetector.detect(trimmed) {
            return ParsedClip(type: .code, textContent: trimmed, imageData: nil, codeLanguage: detection.language)
        }
        return nil
    }

    private static func containsHTMLTags(_ s: String) -> Bool {
        // Match an opening/closing HTML tag like <div>, <a href=…>, </p>, <br/>.
        // Conservative: requires `<` followed by an ASCII letter (or `/` then a
        // letter), so stray comparison operators like `a < b` don't trigger.
        return s.range(of: "</?[a-zA-Z][a-zA-Z0-9]*(\\s[^>]*)?/?>", options: .regularExpression) != nil
    }

    private static func stripHTMLTags(_ html: String) -> String {
        guard let data = html.data(using: .utf8),
              let attrString = try? NSAttributedString(html: data, options: [:], documentAttributes: nil) else {
            return html
        }
        return attrString.string
    }
}
