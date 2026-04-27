import Foundation
import AppKit

struct Clip: Codable, Identifiable {
    let id: UUID
    let type: ClipType
    let textContent: String?
    let imagePath: String?
    let sourceApp: String?
    let contentHash: String
    let createdAt: Date

    init(type: ClipType, textContent: String? = nil, imagePath: String? = nil, sourceApp: String? = nil, contentHash: String) {
        self.id = UUID()
        self.type = type
        self.textContent = textContent
        self.imagePath = imagePath
        self.sourceApp = sourceApp
        self.contentHash = contentHash
        self.createdAt = Date()
    }

    func writeToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch type {
        case .text:
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
        }
    }
}
