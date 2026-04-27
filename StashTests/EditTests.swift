import XCTest
@testable import Stash

final class EditTests: XCTestCase {

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

    func testUpdateClipText() {
        let clip = Clip(type: .text, textContent: "original text", contentHash: "h1")
        store.clips.append(clip)

        store.updateClipText(clip, newText: "edited text")
        XCTAssertEqual(store.clips.first?.textContent, "edited text")
        XCTAssertNotEqual(store.clips.first?.contentHash, "h1")
    }

    func testMoveClipToPinboard() {
        store.createPinboard(name: "Engineering")
        let boardId = store.pinboards.first!.id

        let clip = Clip(type: .text, textContent: "code", contentHash: "h1")
        store.clips.append(clip)

        store.moveClipToPinboard(clip, pinboardId: boardId)
        XCTAssertEqual(store.clips.first?.pinboardId, boardId)

        store.moveClipToPinboard(clip, pinboardId: nil)
        XCTAssertNil(store.clips.first?.pinboardId)
    }
}
