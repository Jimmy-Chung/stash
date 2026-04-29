import XCTest
import SwiftData
@testable import Stash

@MainActor
final class SortOrderTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var context: ModelContext!
    private var store: ClipboardStore!

    override func setUp() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Clip.self, Pinboard.self, configurations: config)
        context = modelContainer.mainContext
        store = ClipboardStore(modelContext: context)
    }

    // U-43: pinned + unpinned mixed list → all sorted by createdAt desc, pinned not first
    func testMixedPinnedUnpinnedSortedByTime() {
        let older = Clip(type: .text, textContent: "older-pinned", contentHash: "h1")
        older.pinnedAt = Date()
        let newer = Clip(type: .text, textContent: "newer-unpinned", contentHash: "h2")
        store.clips = [older, newer]

        let displayed = store.displayClips
        XCTAssertEqual(displayed.first?.textContent, "newer-unpinned")
        XCTAssertEqual(displayed.last?.textContent, "older-pinned")
    }

    // U-44: Pinboard clips sorted by createdAt desc
    func testPinboardClipsSortedByTime() {
        store.createPinboard(name: "Test")
        let boardId = store.pinboards.first!.id

        let older = Clip(type: .text, textContent: "older", contentHash: "h1")
        older.pinboardId = boardId
        let newer = Clip(type: .text, textContent: "newer", contentHash: "h2")
        newer.pinboardId = boardId
        let otherBoard = Clip(type: .text, textContent: "other", contentHash: "h3")

        store.clips = [older, newer, otherBoard]
        store.activePinboardId = boardId

        let displayed = store.displayClips
        XCTAssertEqual(displayed.count, 2)
        XCTAssertEqual(displayed.first?.textContent, "newer")
        XCTAssertEqual(displayed.last?.textContent, "older")
    }

    // U-45: pinned clip sorts after newer unpinned clip
    func testPinnedAfterNewerUnpinned() {
        let pinned = Clip(type: .text, textContent: "pinned-old", contentHash: "h1")
        pinned.pinnedAt = Date()
        // Small delay to ensure different createdAt
        let unpinned = Clip(type: .text, textContent: "unpinned-new", contentHash: "h2")
        store.clips = [pinned, unpinned]

        let displayed = store.displayClips
        // unpinned created after pinned → should be first despite not being pinned
        XCTAssertEqual(displayed.first?.textContent, "unpinned-new")
        XCTAssertEqual(displayed.last?.textContent, "pinned-old")
    }
}
