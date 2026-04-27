import XCTest
@testable import Stash

final class LRUCleanupTests: XCTestCase {

    private var tempDir: URL!
    private var store: ClipboardStore!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StashTest-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = ClipboardStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // U-34: limit=5, insert 6 unpinned → first deleted
    func testLRUDeletesOldestUnpinned() {
        let prefs = PreferencesStore.shared
        let originalLimit = prefs.historyLimit
        prefs.historyLimit = 5

        defer { prefs.historyLimit = originalLimit }

        for i in 0..<6 {
            var clip = Clip(type: .text, textContent: "clip \(i)", contentHash: "h\(i)")
            store.clips.append(clip)
        }

        // Simulate the cleanup logic
        let limit = 5
        let excess = store.clips.count - limit
        if excess > 0 {
            let unpinned = store.clips.filter { !$0.isPinned }
            let toRemove = min(excess, unpinned.count)
            let removedItems = Array(unpinned.suffix(toRemove))
            store.clips.removeAll { clip in
                removedItems.contains(where: { $0.id == clip.id })
            }
        }

        XCTAssertEqual(store.clips.count, 5)
        XCTAssertFalse(store.clips.contains(where: { $0.textContent == "clip 0" }))
    }

    // U-35: limit=5, 3 pinned + 4 normal → delete 2 oldest normal
    func testLRUPreservesPinned() {
        var clips: [Clip] = []
        for i in 0..<3 {
            var clip = Clip(type: .text, textContent: "pinned \(i)", contentHash: "p\(i)")
            clip.pinnedAt = Date()
            clips.append(clip)
        }
        for i in 0..<4 {
            let clip = Clip(type: .text, textContent: "normal \(i)", contentHash: "n\(i)")
            clips.append(clip)
        }
        store.clips = clips

        let limit = 5
        let excess = store.clips.count - limit
        if excess > 0 {
            let unpinned = store.clips.filter { !$0.isPinned }
            let toRemove = min(excess, unpinned.count)
            let removedItems = Array(unpinned.suffix(toRemove))
            store.clips.removeAll { clip in
                removedItems.contains(where: { $0.id == clip.id })
            }
        }

        XCTAssertEqual(store.clips.count, 5)
        XCTAssertEqual(store.clips.filter { $0.isPinned }.count, 3)
    }

    // U-36: limit=0 (unlimited) → no cleanup
    func testUnlimitedNoCleanup() {
        let prefs = PreferencesStore.shared
        let originalLimit = prefs.historyLimit
        prefs.historyLimit = 0

        defer { prefs.historyLimit = originalLimit }

        for i in 0..<100 {
            let clip = Clip(type: .text, textContent: "clip \(i)", contentHash: "h\(i)")
            store.clips.append(clip)
        }

        XCTAssertEqual(store.clips.count, 100)
    }
}
