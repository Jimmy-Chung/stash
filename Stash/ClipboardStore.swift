import Foundation
import AppKit

final class ClipboardStore: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var pinboards: [Pinboard] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""
    @Published var filterType: ClipType?
    @Published var activePinboardId: UUID?

    var displayClips: [Clip] {
        var result = clips

        // Filter by active pinboard
        if let boardId = activePinboardId {
            result = result.filter { $0.pinboardId == boardId }
        }

        if let type = filterType {
            result = SearchService.filter(clips: result, type: type)
        }
        if !searchText.isEmpty {
            result = SearchService.filter(clips: result, query: searchText)
        }

        // Pinned items first
        return result.sorted { ($0.pinnedAt != nil && $1.pinnedAt == nil) || (($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) && $0.pinnedAt != nil && $1.pinnedAt != nil) }
    }

    var activePinboard: Pinboard? {
        guard let id = activePinboardId else { return nil }
        return pinboards.first { $0.id == id }
    }

    var sortedPinboards: [Pinboard] {
        pinboards.sorted { $0.order < $1.order }
    }

    private let storageURL: URL
    private let pinboardsURL: URL
    private var lastContentHash: String?
    let searchService = SearchService()

    init(directory: URL? = nil) {
        let stashDir: URL
        if let dir = directory {
            stashDir = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            stashDir = appSupport.appendingPathComponent("Stash", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: stashDir, withIntermediateDirectories: true)
        storageURL = stashDir.appendingPathComponent("clips.json")
        pinboardsURL = stashDir.appendingPathComponent("pinboards.json")
        load()

        searchService.onSearch = { [weak self] query in
            DispatchQueue.main.async {
                self?.searchText = query
                self?.selectedIndex = 0
            }
        }
    }

    // MARK: - Clip Processing

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

        if clip.type == .link, let url = clip.textContent {
            fetchLinkMetadata(for: url, clipId: clip.id)
        }
    }

    // MARK: - Clip Operations

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

    func togglePin(_ clip: Clip) {
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[idx].pinnedAt = clips[idx].pinnedAt == nil ? Date() : nil
        save()
    }

    func updateClipText(_ clip: Clip, newText: String) {
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[idx].textContent = newText
        clips[idx].contentHash = DedupeHasher.hash(data: Data(newText.utf8))
        save()
    }

    func moveClipToPinboard(_ clip: Clip, pinboardId: UUID?) {
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[idx].pinboardId = pinboardId
        save()
    }

    // MARK: - Search & Filter

    func updateSearch(_ query: String) {
        searchService.search(query: query)
    }

    func clearSearch() {
        searchText = ""
        filterType = nil
        selectedIndex = 0
    }

    // MARK: - Navigation

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

    // MARK: - Pinboard Operations

    func createPinboard(name: String, icon: String = "folder") {
        let order = pinboards.count
        let board = Pinboard(name: name, icon: icon, order: order)
        pinboards.append(board)
        savePinboards()
    }

    func renamePinboard(_ board: Pinboard, newName: String) {
        guard let idx = pinboards.firstIndex(where: { $0.id == board.id }) else { return }
        pinboards[idx].name = newName
        savePinboards()
    }

    func deletePinboard(_ board: Pinboard) {
        // Unlink all clips from this pinboard
        for idx in clips.indices where clips[idx].pinboardId == board.id {
            clips[idx].pinboardId = nil
        }
        pinboards.removeAll { $0.id == board.id }
        if activePinboardId == board.id {
            activePinboardId = nil
        }
        save()
        savePinboards()
    }

    func switchToNextPinboard() {
        let sorted = sortedPinboards
        guard !sorted.isEmpty else { return }

        if let currentId = activePinboardId,
           let currentIdx = sorted.firstIndex(where: { $0.id == currentId }),
           currentIdx + 1 < sorted.count {
            activePinboardId = sorted[currentIdx + 1].id
        } else {
            activePinboardId = nil // Back to "All"
        }
        selectedIndex = 0
    }

    func switchToPreviousPinboard() {
        let sorted = sortedPinboards
        guard !sorted.isEmpty else { return }

        if let currentId = activePinboardId,
           let currentIdx = sorted.firstIndex(where: { $0.id == currentId }),
           currentIdx > 0 {
            activePinboardId = sorted[currentIdx - 1].id
        } else {
            activePinboardId = sorted.last?.id // Wrap to last
        }
        selectedIndex = 0
    }

    // MARK: - Persistence

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

        if let data = try? Data(contentsOf: pinboardsURL) {
            pinboards = (try? JSONDecoder().decode([Pinboard].self, from: data)) ?? []
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(clips) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func savePinboards() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(pinboards) else { return }
        try? data.write(to: pinboardsURL, options: .atomic)
    }
}
