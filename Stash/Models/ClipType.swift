import Foundation

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case link
    case rtf
    case file
    case color
    case code

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .link: return "Link"
        case .rtf: return "Rich Text"
        case .file: return "File"
        case .color: return "Color"
        case .code: return "Code"
        }
    }

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .link: return "link"
        case .rtf: return "doc.richtext"
        case .file: return "doc"
        case .color: return "paintpalette"
        case .code: return "curlybraces"
        }
    }
}
