import Foundation
import AppKit
import SwiftData

final class ClipboardStore: ObservableObject {
    @Published var clips: [Clip] = [] { didSet { recomputeDisplayClips() } }
    @Published var pinboards: [Pinboard] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = "" { didSet { recomputeDisplayClips() } }
    @Published var filterType: ClipType? { didSet { recomputeDisplayClips() } }
    @Published var activePinboardId: UUID? { didSet { recomputeDisplayClips() } }
    @Published private(set) var displayClips: [Clip] = []
    @Published private(set) var pinboardClipCounts: [UUID: Int] = [:]

    var activePinboard: Pinboard? {
        guard let id = activePinboardId else { return nil }
        return pinboards.first { $0.id == id }
    }

    var sortedPinboards: [Pinboard] {
        pinboards.sorted { $0.order < $1.order }
    }

    static let pinboardPalette: [String] = [
        "#F4A261", "#E76F51", "#2A9D8F", "#6C8EEF", "#8B5CF6",
        "#06B6D4", "#F7B267", "#34D399", "#F472B6", "#94A3B8"
    ]

    private func nextPinboardColor() -> String {
        let palette = Self.pinboardPalette
        let used = Set(pinboards.map { $0.accent })
        for color in palette where !used.contains(color) { return color }
        return palette[pinboards.count % palette.count]
    }

    private var modelContext: ModelContext
    private var lastContentHash: String?
    let searchService = SearchService()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFromContext()

        searchService.onSearch = { [weak self] query in
            DispatchQueue.main.async {
                // Avoid triggering @Published when value hasn't changed (prevents SwiftUI update loop)
                if self?.searchText != query {
                    self?.searchText = query
                    self?.selectedIndex = 0
                }
            }
        }
        recomputeDisplayClips()
    }

    // MARK: - Clip Processing

    func processClip() {
        let pasteboard = NSPasteboard.general
        guard let result = ClipParser.parse(pasteboard) else { return }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // Image processing is heavy (hash, disk write, metadata) — offload to background
        if result.type == .image, let imageData = result.imageData {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let hash = DedupeHasher.hash(data: result.hashData)

                // Snapshot lastContentHash for dedup check (benign race acceptable)
                guard hash != self?.lastContentHash else { return }
                guard let path = BlobStore.shared.write(imageData) else { return }

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.lastContentHash = hash

                    let clip = Clip(
                        type: result.type,
                        textContent: nil,
                        sourceApp: sourceApp,
                        contentHash: hash,
                        title: result.title,
                        imageWidth: result.imageWidth,
                        imageHeight: result.imageHeight,
                        dominantColors: result.dominantColors
                    )
                    clip.imagePath = path
                    self.modelContext.insert(clip)
                    if let boardId = self.activePinboardId { clip.pinboardId = boardId }
                    self.clips.insert(clip, at: 0)
                    self.selectedIndex = 0
                    if PreferencesStore.shared.soundEnabled {
                        NSSound(named: "Tink")?.play()
                    }
                }
            }
            return
        }

        // Text-based clips — fast, stay on main thread
        let hash = DedupeHasher.hash(data: result.hashData)
        if hash == lastContentHash { return }
        lastContentHash = hash

        let clip = Clip(
            type: result.type,
            textContent: result.textContent,
            sourceApp: sourceApp,
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

        modelContext.insert(clip)

        if let boardId = activePinboardId {
            clip.pinboardId = boardId
        }

        clips.insert(clip, at: 0)
        selectedIndex = 0

        if PreferencesStore.shared.soundEnabled {
            NSSound(named: "Tink")?.play()
        }

        if clip.type == .link, let url = clip.textContent {
            fetchLinkMetadata(for: url, clipId: clip.id)
        }
    }

    // MARK: - Clip Operations

    func deleteClips(_ clipsToRemove: [Clip]) {
        let ids = Set(clipsToRemove.map { $0.id })
        for item in clipsToRemove {
            if let path = item.imagePath {
                BlobStore.shared.delete(path)
            }
            modelContext.delete(item)
        }
        clips.removeAll { ids.contains($0.id) }
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

    func pinToPinboard(_ clip: Clip, pinboardId: UUID) {
        clip.pinboardId = pinboardId
        clip.pinnedAt = Date()
        recomputeDisplayClips()
    }

    func unpin(_ clip: Clip) {
        clip.pinnedAt = nil
        clip.pinboardId = nil
        recomputeDisplayClips()
    }

    func updateClipText(_ clip: Clip, newText: String) {
        clip.textContent = newText
        clip.contentHash = DedupeHasher.hash(data: Data(newText.utf8))
    }

    func moveClipToPinboard(_ clip: Clip, pinboardId: UUID?) {
        clip.pinboardId = pinboardId
        if pinboardId != nil {
            clip.pinnedAt = clip.pinnedAt ?? Date()
        }
        recomputeDisplayClips()
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
        let start = CFAbsoluteTimeGetCurrent()
        guard selectedIndex < displayClips.count - 1 else { return }
        selectedIndex += 1
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        if ms > 1 { NSLog("[Perf] selectNext: %.2fms", ms) }
    }

    func selectPrevious() {
        let start = CFAbsoluteTimeGetCurrent()
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        if ms > 1 { NSLog("[Perf] selectPrevious: %.2fms", ms) }
    }

    func clip(at index: Int) -> Clip? {
        let displayed = displayClips
        guard index >= 0, index < displayed.count else { return nil }
        return displayed[index]
    }

    // MARK: - Pinboard Operations

    func createPinboard(name: String, icon: String = "folder") {
        let order = pinboards.count
        let accent = nextPinboardColor()
        let board = Pinboard(name: name, icon: icon, accent: accent, order: order)
        modelContext.insert(board)
        do {
            try modelContext.save()
        } catch {
            print("Failed to create pinboard: \(error)")
            modelContext.rollback()
            return
        }
        pinboards.append(board)
    }

    @discardableResult
    func createPinboardAndPin(clip: Clip) -> Pinboard {
        var index = 0
        let existingNames = Set(pinboards.map { $0.name })
        while existingNames.contains("Pinboard \(index)") { index += 1 }
        let name = "Pinboard \(index)"

        let order = pinboards.count
        let accent = nextPinboardColor()
        let board = Pinboard(name: name, icon: "folder", accent: accent, order: order)
        modelContext.insert(board)
        do {
            try modelContext.save()
        } catch {
            print("Failed to create pinboard: \(error)")
            modelContext.rollback()
            return board
        }
        pinboards.append(board)
        pinToPinboard(clip, pinboardId: board.id)
        return board
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
        recomputeDisplayClips()
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

    private func recomputeDisplayClips() {
        let start = CFAbsoluteTimeGetCurrent()
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

        displayClips = result.sorted { $0.createdAt > $1.createdAt }

        var counts: [UUID: Int] = [:]
        for clip in clips where clip.pinboardId != nil {
            counts[clip.pinboardId!, default: 0] += 1
        }
        pinboardClipCounts = counts

        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        if ms > 5 { NSLog("[Perf] recomputeDisplayClips: %.1fms, %d clips", ms, displayClips.count) }
    }

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
        var clipDescriptor = FetchDescriptor<Clip>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        clipDescriptor.fetchLimit = 200
        do {
            clips = try modelContext.fetch(clipDescriptor)
        } catch {
            NSLog("[Stash] Failed to fetch clips: \(error)")
            clips = []
        }

        let boardDescriptor = FetchDescriptor<Pinboard>(sortBy: [SortDescriptor(\.order)])
        do {
            pinboards = try modelContext.fetch(boardDescriptor)
        } catch {
            NSLog("[Stash] Failed to fetch pinboards: \(error)")
            pinboards = []
        }

        backfillPinboardColorsIfNeeded()

        if let first = clips.first {
            lastContentHash = first.contentHash
        }
    }

    private func backfillPinboardColorsIfNeeded() {
        guard pinboards.count > 1 else { return }
        // Detect duplicate colors (e.g. legacy boards all using the default accent).
        let colors = pinboards.map { $0.accent }
        guard Set(colors).count != colors.count else { return }
        let palette = Self.pinboardPalette
        let sorted = pinboards.sorted { $0.order < $1.order }
        for (idx, board) in sorted.enumerated() {
            board.accent = palette[idx % palette.count]
        }
        try? modelContext.save()
    }
}
