import Foundation
import AppKit

struct Clip: Codable, Identifiable {
    let id: UUID
    let type: ClipType
    var textContent: String?
    var imagePath: String?
    let sourceApp: String?
    var contentHash: String
    let createdAt: Date

    // v0.2 metadata
    var title: String?
    var faviconPath: String?
    var imageWidth: Int?
    var imageHeight: Int?
    var dominantColors: [String]?
    var colorHex: String?
    var colorRGB: String?
    var codeLanguage: String?
    var fileName: String?

    // v0.3 organization
    var pinboardId: UUID?
    var pinnedAt: Date?

    var isPinned: Bool { pinnedAt != nil }

    init(
        type: ClipType,
        textContent: String? = nil,
        imagePath: String? = nil,
        sourceApp: String? = nil,
        contentHash: String,
        title: String? = nil,
        faviconPath: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        dominantColors: [String]? = nil,
        colorHex: String? = nil,
        colorRGB: String? = nil,
        codeLanguage: String? = nil,
        fileName: String? = nil,
        pinboardId: UUID? = nil,
        pinnedAt: Date? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.textContent = textContent
        self.imagePath = imagePath
        self.sourceApp = sourceApp
        self.contentHash = contentHash
        self.createdAt = Date()
        self.title = title
        self.faviconPath = faviconPath
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.dominantColors = dominantColors
        self.colorHex = colorHex
        self.colorRGB = colorRGB
        self.codeLanguage = codeLanguage
        self.fileName = fileName
        self.pinboardId = pinboardId
        self.pinnedAt = pinnedAt
    }

    func writeToPasteboard(plainTextOnly: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if plainTextOnly {
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }
            return
        }

        switch type {
        case .text, .code, .address:
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .link:
            if let url = textContent {
                pasteboard.setString(url, forType: .string)
                if URL(string: url) != nil {
                    pasteboard.setString(url, forType: .URL)
                }
            }
        case .image:
            if let path = imagePath {
                let url = URL(fileURLWithPath: path)
                if let data = try? Data(contentsOf: url) {
                    pasteboard.setData(data, forType: .png)
                }
            }
        case .rtf:
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }
            if let data = rtfDataFromStorage {
                pasteboard.setData(data, forType: .rtf)
            }
        case .html:
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }
            if let html = textContent, let data = html.data(using: .utf8) {
                pasteboard.setData(data, forType: .html)
            }
        case .file:
            if let path = textContent {
                let url = URL(fileURLWithPath: path)
                pasteboard.writeObjects([url as NSURL])
            }
        case .color:
            if let hex = colorHex {
                pasteboard.setString(hex, forType: .string)
            }
        }
    }

    private var rtfDataFromStorage: Data? {
        guard let text = textContent else { return nil }
        let attrStr = NSAttributedString(string: text)
        let range = NSRange(location: 0, length: attrStr.length)
        return try? attrStr.data(
            from: range,
            documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    var displayTitle: String {
        if let title = title, !title.isEmpty { return title }
        switch type {
        case .link:
            if let url = URL(string: textContent ?? ""), let host = url.host {
                return host
            }
            return textContent ?? "Link"
        case .file:
            return fileName ?? textContent ?? "File"
        case .code:
            return codeLanguage ?? "Code"
        case .color:
            return colorHex ?? "Color"
        default:
            if let text = textContent, text.count > 60 {
                return String(text.prefix(60))
            }
            return textContent ?? type.displayName
        }
    }
}
