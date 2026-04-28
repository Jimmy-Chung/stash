import Foundation
import SwiftData

@Model
final class Pinboard {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var accent: String
    var order: Int

    init(name: String, icon: String = "folder", accent: String = "#F4A261", order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.accent = accent
        self.order = order
    }
}
