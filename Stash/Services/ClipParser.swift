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
        case .text, .link, .code, .address, .color, .rtf, .html:
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
        // 1. Image data (PNG, TIFF)
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            var clip = ParsedClip(type: .image, textContent: nil, imageData: data)
            if let meta = ImageMetadataService.extract(from: data) {
                clip.imageWidth = meta.width
                clip.imageHeight = meta.height
                clip.dominantColors = meta.dominantColors
            }
            return clip
        }

        // 2. File URL
        if let urlString = pasteboard.string(forType: .URL),
           urlString.hasPrefix("file://"),
           let url = URL(string: urlString),
           url.isFileURL {
            let path = url.path
            let fileName = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension.uppercased()
            let title = ext.isEmpty ? fileName : "\(fileName).\(ext)"
            return ParsedClip(type: .file, textContent: path, imageData: nil, fileName: title)
        }

        // 3. RTF data
        if let data = pasteboard.data(forType: .rtf) {
            let attrString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            let text = attrString?.string ?? ""
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return ParsedClip(type: .rtf, textContent: text, imageData: nil)
        }

        // 4. HTML data
        if let data = pasteboard.data(forType: .html) {
            let html = String(data: data, encoding: .utf8) ?? ""
            let text = stripHTMLTags(html)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return ParsedClip(type: .html, textContent: text, imageData: nil)
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

            // Check if text is a URL
            if let url = URL(string: trimmed),
               let scheme = url.scheme,
               (scheme == "http" || scheme == "https"),
               url.host != nil {
                return ParsedClip(type: .link, textContent: trimmed, imageData: nil)
            }

            // Color detection
            if let color = ColorParser.parse(trimmed) {
                return ParsedClip(type: .color, textContent: trimmed, imageData: nil, colorHex: color.hex, colorRGB: color.rgb)
            }

            // Address detection
            if let address = AddressDetector.detect(in: trimmed) {
                return ParsedClip(type: .address, textContent: address, imageData: nil)
            }

            // Code detection
            if let detection = CodeLanguageDetector.detect(trimmed) {
                return ParsedClip(type: .code, textContent: trimmed, imageData: nil, codeLanguage: detection.language)
            }

            return ParsedClip(type: .text, textContent: text, imageData: nil)
        }

        return nil
    }

    private static func stripHTMLTags(_ html: String) -> String {
        guard let data = html.data(using: .utf8),
              let attrString = try? NSAttributedString(html: data, options: [:], documentAttributes: nil) else {
            return html
        }
        return attrString.string
    }
}
