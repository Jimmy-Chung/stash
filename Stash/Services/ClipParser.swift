import AppKit

struct ParsedClip {
    let type: ClipType
    let textContent: String?
    let imageData: Data?

    var hashData: Data {
        switch type {
        case .text, .link:
            return Data((textContent ?? "").utf8)
        case .image:
            return imageData ?? Data()
        }
    }
}

enum ClipParser {
    static func parse(_ pasteboard: NSPasteboard) -> ParsedClip? {
        // 1. Check for image data (PNG, TIFF)
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            return ParsedClip(type: .image, textContent: nil, imageData: data)
        }

        // 2. Check for URL
        if let urlString = pasteboard.string(forType: .URL),
           !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           urlString.hasPrefix("http") {
            return ParsedClip(type: .link, textContent: urlString, imageData: nil)
        }

        // 3. Check for string content
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Check if text is a URL
            if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
               let scheme = url.scheme,
               (scheme == "http" || scheme == "https"),
               url.host != nil {
                return ParsedClip(type: .link, textContent: text.trimmingCharacters(in: .whitespacesAndNewlines), imageData: nil)
            }
            return ParsedClip(type: .text, textContent: text, imageData: nil)
        }

        return nil
    }
}
