import Foundation
import AppKit

final class ClipboardStore: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""
    @Published var filterType: ClipType?

    var displayClips: [Clip] {
        var result = clips
        if let type = filterType {
            result = SearchService.filter(clips: result, type: type)
        }
        if !searchText.isEmpty {
            result = SearchService.filter(clips: result, query: searchText)
        }
        return result
    }

    private let storageURL: URL
    private var lastContentHash: String?
    let searchService = SearchService()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let stashDir = appSupport.appendingPathComponent("Stash", isDirectory: true)
        try? FileManager.default.createDirectory(at: stashDir, withIntermediateDirectories: true)
        storageURL = stashDir.appendingPathComponent("clips.json")
        load()

        searchService.onSearch = { [weak self] query in
            DispatchQueue.main.async {
                self?.searchText = query
                self?.selectedIndex = 0
            }
        }
    }

    func processClip() {
        let pasteboard = NSPasteboard.general
        guard let result = ClipParser.parse(pasteboard) else { return }

        let hash = DedupeHasher.hash(data: result.hashData)
        if hash == lastContentHash { return }
        lastContentHash = hash

        let imagePath: String? = nil
        var clip = Clip(
            type: result.type,
            textContent: result.textContent,
            imagePath: imagePath,
            sourceApp: NSWorkspace.shared.frontmostApplication?.localizedName,
            contentHash: hash,
            title: result.title,
            imageWidth: result.imageWidth,
            imageHeight: result.imageHeight,
            dominantColors: result.dominantColors,
            colorHex: result.colorHex,
            colorRGB: result.colorRGB,
            codeLanguage: result.codeLanguage,
            fileName: result.fileName
        )

        if result.type == .image, let imageData = result.imageData {
            guard let path = BlobStore.shared.write(imageData) else { return }
            clip.imagePath = path
        }

        clips.insert(clip, at: 0)
        selectedIndex = 0
        save()

        // Async metadata enrichment for links
        if clip.type == .link, let url = clip.textContent {
            fetchLinkMetadata(for: url, clipId: clip.id)
        }
    }

    func deleteClip(_ clip: Clip) {
        if let path = clip.imagePath {
            BlobStore.shared.delete(path)
        }
        clips.removeAll { $0.id == clip.id }
        if selectedIndex >= displayClips.count {
            selectedIndex = max(0, displayClips.count - 1)
        }
        save()
    }

    func updateSearch(_ query: String) {
        searchService.search(query: query)
    }

    func clearSearch() {
        searchText = ""
        filterType = nil
        selectedIndex = 0
    }

    func selectNext() {
        guard selectedIndex < displayClips.count - 1 else { return }
        selectedIndex += 1
    }

    func selectPrevious() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    func clip(at index: Int) -> Clip? {
        let displayed = displayClips
        guard index >= 0, index < displayed.count else { return nil }
        return displayed[index]
    }

    func globalIndex(for displayedIndex: Int) -> Int? {
        guard let clip = clip(at: displayedIndex) else { return nil }
        return clips.firstIndex(where: { $0.id == clip.id })
    }

    private func fetchLinkMetadata(for urlString: String, clipId: UUID) {
        LinkMetadataService.shared.fetchMetadata(for: urlString) { [weak self] meta in
            guard let meta = meta else { return }
            DispatchQueue.main.async {
                guard let self = self,
                      let idx = self.clips.firstIndex(where: { $0.id == clipId }) else { return }
                self.clips[idx].title = meta.title
                self.clips[idx].faviconPath = meta.faviconPath
                self.save()
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        clips = (try? JSONDecoder().decode([Clip].self, from: data)) ?? []
        if let first = clips.first {
            lastContentHash = first.contentHash
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(clips) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
