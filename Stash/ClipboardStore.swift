import Foundation
import AppKit

final class ClipboardStore: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var selectedIndex: Int = 0

    private let storageURL: URL
    private var lastContentHash: String?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let stashDir = appSupport.appendingPathComponent("Stash", isDirectory: true)
        try? FileManager.default.createDirectory(at: stashDir, withIntermediateDirectories: true)
        storageURL = stashDir.appendingPathComponent("clips.json")
        load()
    }

    func processClip() {
        let pasteboard = NSPasteboard.general
        guard let result = ClipParser.parse(pasteboard) else { return }

        let hash = DedupeHasher.hash(data: result.hashData)
        if hash == lastContentHash { return }
        lastContentHash = hash

        var imagePath: String? = nil
        if result.type == .image, let imageData = result.imageData {
            imagePath = BlobStore.shared.write(imageData)
        }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
        let clip = Clip(
            type: result.type,
            textContent: result.textContent,
            imagePath: imagePath,
            sourceApp: sourceApp,
            contentHash: hash
        )
        clips.insert(clip, at: 0)
        selectedIndex = 0
        save()
    }

    func deleteClip(_ clip: Clip) {
        if let path = clip.imagePath {
            BlobStore.shared.delete(path)
        }
        clips.removeAll { $0.id == clip.id }
        if selectedIndex >= clips.count {
            selectedIndex = max(0, clips.count - 1)
        }
        save()
    }

    func selectNext() {
        guard selectedIndex < clips.count - 1 else { return }
        selectedIndex += 1
    }

    func selectPrevious() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    func clip(at index: Int) -> Clip? {
        guard index >= 0, index < clips.count else { return nil }
        return clips[index]
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        clips = (try? JSONDecoder().decode([Clip].self, from: data)) ?? []
        // Restore last hash for dedup
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
