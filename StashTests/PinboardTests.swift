import XCTest
@testable import Stash

final class PinboardTests: XCTestCase {

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

    func testCreatePinboard() {
        store.createPinboard(name: "Engineering")
        XCTAssertEqual(store.pinboards.count, 1)
        XCTAssertEqual(store.pinboards.first?.name, "Engineering")
    }

    func testDeletePinboardUnlinksClips() {
        store.createPinboard(name: "TestBoard")
        let boardId = store.pinboards.first!.id

        var clip = Clip(type: .text, textContent: "hello", contentHash: "h1")
        clip.pinboardId = boardId
        store.clips.append(clip)

        store.deletePinboard(store.pinboards.first!)
        XCTAssertEqual(store.clips.count, 1)
        XCTAssertNil(store.clips.first?.pinboardId)
    }

    func testTogglePin() {
        let clip = Clip(type: .text, textContent: "pin me", contentHash: "h1")
        store.clips.append(clip)

        XCTAssertNil(store.clips.first?.pinnedAt)
        store.togglePin(clip)
        XCTAssertNotNil(store.clips.first?.pinnedAt)

        store.togglePin(clip)
        XCTAssertNil(store.clips.first?.pinnedAt)
    }

    func testPinnedSortFirst() {
        var clip1 = Clip(type: .text, textContent: "unpinned", contentHash: "h1")
        var clip2 = Clip(type: .text, textContent: "pinned", contentHash: "h2")
        clip2.pinnedAt = Date()
        store.clips = [clip1, clip2]

        let displayed = store.displayClips
        XCTAssertEqual(displayed.first?.textContent, "pinned")
        XCTAssertEqual(displayed.last?.textContent, "unpinned")
    }

    func testRenamePinboard() {
        store.createPinboard(name: "Old Name")
        let board = store.pinboards.first!
        store.renamePinboard(board, newName: "New Name")
        XCTAssertEqual(store.pinboards.first?.name, "New Name")
    }
}
