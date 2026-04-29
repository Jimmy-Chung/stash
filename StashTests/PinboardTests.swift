import XCTest
import SwiftData
@testable import Stash

@MainActor
final class PinboardTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var context: ModelContext!
    private var store: ClipboardStore!

    override func setUp() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Clip.self, Pinboard.self, configurations: config)
        context = modelContainer.mainContext
        store = ClipboardStore(modelContext: context)
    }

    func testCreatePinboard() {
        store.createPinboard(name: "Engineering")
        XCTAssertEqual(store.pinboards.count, 1)
        XCTAssertEqual(store.pinboards.first?.name, "Engineering")
    }

    func testDeletePinboardUnlinksClips() {
        store.createPinboard(name: "TestBoard")
        let boardId = store.pinboards.first!.id

        let clip = Clip(type: .text, textContent: "hello", contentHash: "h1")
        clip.pinboardId = boardId
        store.clips.append(clip)
        context.insert(clip)

        store.deletePinboard(store.pinboards.first!)
        XCTAssertEqual(store.clips.count, 1)
        XCTAssertNil(store.clips.first?.pinboardId)
    }

    func testTogglePin() {
        let clip = Clip(type: .text, textContent: "pin me", contentHash: "h1")
        store.clips.append(clip)
        context.insert(clip)

        XCTAssertNil(store.clips.first?.pinnedAt)
        store.togglePin(clip)
        XCTAssertNotNil(store.clips.first?.pinnedAt)

        store.togglePin(clip)
        XCTAssertNil(store.clips.first?.pinnedAt)
    }

    func testPinnedSortByTimeOnly() {
        // F-56: pinned items sort by createdAt, not pinned-first
        let clip1 = Clip(type: .text, textContent: "pinned", contentHash: "h1")
        clip1.pinnedAt = Date()
        let clip2 = Clip(type: .text, textContent: "unpinned", contentHash: "h2")
        store.clips = [clip1, clip2]

        let displayed = store.displayClips
        // Both created almost simultaneously; order is by createdAt desc
        // clip2 created after clip1, so clip2 should be first
        XCTAssertEqual(displayed.first?.textContent, "unpinned")
        XCTAssertEqual(displayed.last?.textContent, "pinned")
    }

    func testRenamePinboard() {
        store.createPinboard(name: "Old Name")
        let board = store.pinboards.first!
        store.renamePinboard(board, newName: "New Name")
        XCTAssertEqual(store.pinboards.first?.name, "New Name")
    }
}
