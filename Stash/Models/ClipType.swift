import Foundation

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case link
    case rtf
    case html
    case file
    case color
    case code
    case address

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .link: return "Link"
        case .rtf: return "Rich Text"
        case .html: return "HTML"
        case .file: return "File"
        case .color: return "Color"
        case .code: return "Code"
        case .address: return "Address"
        }
    }

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .link: return "link"
        case .rtf: return "doc.richtext"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .file: return "doc"
        case .color: return "paintpalette"
        case .code: return "curlybraces"
        case .address: return "mappin.and.ellipse"
        }
    }
}
