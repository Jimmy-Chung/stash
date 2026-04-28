import Foundation
import AppKit
import SwiftData

final class ClipboardStore: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var pinboards: [Pinboard] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""
    @Published var filterType: ClipType?
    @Published var activePinboardId: UUID?

    var displayClips: [Clip] {
        var result = clips

        if let boardId = activePinboardId {
            result = result.filter { $0.pinboardId == boardId }
        }

        if let type = filterType {
            result = SearchService.filter(clips: result, type: type)
        }
        if !searchText.isEmpty {
            result = SearchService.filter(clips: result, query: searchText)
        }

        return result.sorted { ($0.pinnedAt != nil && $1.pinnedAt == nil) || (($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) && $0.pinnedAt != nil && $1.pinnedAt != nil) }
    }

    var activePinboard: Pinboard? {
        guard let id = activePinboardId else { return nil }
        return pinboards.first { $0.id == id }
    }

    var sortedPinboards: [Pinboard] {
        pinboards.sorted { $0.order < $1.order }
    }

    private var modelContext: ModelContext
    private var lastContentHash: String?
    let searchService = SearchService()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFromContext()

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

        let clip = Clip(
            type: result.type,
            textContent: result.textContent,
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

        modelContext.insert(clip)

        if let boardId = activePinboardId {
            clip.pinboardId = boardId
        }

        clips.insert(clip, at: 0)
        selectedIndex = 0

        if clip.type == .link, let url = clip.textContent {
            fetchLinkMetadata(for: url, clipId: clip.id)
        }
    }

    // MARK: - Clip Operations

    func deleteClips(_ clipsToRemove: [Clip]) {
        for item in clipsToRemove {
            if let path = item.imagePath {
                BlobStore.shared.delete(path)
            }
            modelContext.delete(item)
        }
        clips.removeAll { clip in
            clipsToRemove.contains(where: { $0.id == clip.id })
        }
    }

    func deleteClip(_ clip: Clip) {
        if let path = clip.imagePath {
            BlobStore.shared.delete(path)
        }
        clips.removeAll { $0.id == clip.id }
        modelContext.delete(clip)
        if selectedIndex >= displayClips.count {
            selectedIndex = max(0, displayClips.count - 1)
        }
    }

    func togglePin(_ clip: Clip) {
        clip.pinnedAt = clip.pinnedAt == nil ? Date() : nil
    }

    func updateClipText(_ clip: Clip, newText: String) {
        clip.textContent = newText
        clip.contentHash = DedupeHasher.hash(data: Data(newText.utf8))
    }

    func moveClipToPinboard(_ clip: Clip, pinboardId: UUID?) {
        clip.pinboardId = pinboardId
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
        modelContext.insert(board)
        pinboards.append(board)
    }

    func renamePinboard(_ board: Pinboard, newName: String) {
        board.name = newName
    }

    func deletePinboard(_ board: Pinboard) {
        for clip in clips where clip.pinboardId == board.id {
            clip.pinboardId = nil
        }
        pinboards.removeAll { $0.id == board.id }
        modelContext.delete(board)
        if activePinboardId == board.id {
            activePinboardId = nil
        }
    }

    func switchToNextPinboard() {
        let sorted = sortedPinboards
        guard !sorted.isEmpty else { return }

        if let currentId = activePinboardId,
           let currentIdx = sorted.firstIndex(where: { $0.id == currentId }),
           currentIdx + 1 < sorted.count {
            activePinboardId = sorted[currentIdx + 1].id
        } else {
            activePinboardId = nil
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
            activePinboardId = sorted.last?.id
        }
        selectedIndex = 0
    }

    // MARK: - Data Retention

    func cleanupExpiredClips(retentionDays: Int = 90) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let expired = clips.filter { $0.createdAt < cutoff && $0.pinboardId == nil }
        guard !expired.isEmpty else { return }
        deleteClips(expired)
    }

    // MARK: - Private

    private func fetchLinkMetadata(for urlString: String, clipId: UUID) {
        LinkMetadataService.shared.fetchMetadata(for: urlString) { [weak self] meta in
            guard let meta = meta else { return }
            DispatchQueue.main.async {
                guard let self = self,
                      let clip = self.clips.first(where: { $0.id == clipId }) else { return }
                clip.title = meta.title
                clip.faviconPath = meta.faviconPath
            }
        }
    }

    private func loadFromContext() {
        let clipDescriptor = FetchDescriptor<Clip>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        clips = (try? modelContext.fetch(clipDescriptor)) ?? []

        let boardDescriptor = FetchDescriptor<Pinboard>(sortBy: [SortDescriptor(\.order)])
        pinboards = (try? modelContext.fetch(boardDescriptor)) ?? []

        if let first = clips.first {
            lastContentHash = first.contentHash
        }
    }
}
