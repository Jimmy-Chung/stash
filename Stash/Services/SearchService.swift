import Foundation

final class SearchService {
    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval

    var onSearch: ((String) -> Void)?

    init(debounceInterval: TimeInterval = 0.12) {
        self.debounceInterval = debounceInterval
    }

    func search(query: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.onSearch?(query)
        }
    }

    func cancel() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }

    static func filter(clips: [Clip], query: String) -> [Clip] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return clips }

        let lower = query.lowercased()
        return clips.filter { clip in
            (clip.textContent?.lowercased().contains(lower) ?? false) ||
            (clip.sourceApp?.lowercased().contains(lower) ?? false) ||
            (clip.title?.lowercased().contains(lower) ?? false) ||
            (clip.fileName?.lowercased().contains(lower) ?? false) ||
            (clip.codeLanguage?.lowercased().contains(lower) ?? false) ||
            (clip.colorHex?.lowercased().contains(lower) ?? false)
        }
    }

    static func filter(clips: [Clip], type: ClipType?) -> [Clip] {
        guard let type = type else { return clips }
        return clips.filter { $0.type == type }
    }

    static func highlight(_ text: String, query: String) -> AttributedString {
        guard !query.isEmpty else { return AttributedString(text) }

        var attributed = AttributedString(text)
        let lower = text.lowercased()
        let queryLower = query.lowercased()

        var searchStart = lower.startIndex
        while let range = lower.range(of: queryLower, range: searchStart..<lower.endIndex) {
            let attrRange = AttributedString.Index(range.lowerBound, within: attributed)!
                ..< AttributedString.Index(range.upperBound, within: attributed)!
            attributed[attrRange].backgroundColor = .orange.opacity(0.4)
            attributed[attrRange].foregroundColor = .white
            searchStart = range.upperBound
        }

        return attributed
    }
}
