import XCTest
import SwiftData
@testable import Stash

@MainActor
final class EditTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var context: ModelContext!
    private var store: ClipboardStore!

    override func setUp() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Clip.self, Pinboard.self, configurations: config)
        context = modelContainer.mainContext
        store = ClipboardStore(modelContext: context)
    }

    func testUpdateClipText() {
        let clip = Clip(type: .text, textContent: "original text", contentHash: "h1")
        store.clips.append(clip)
        context.insert(clip)

        store.updateClipText(clip, newText: "edited text")
        XCTAssertEqual(store.clips.first?.textContent, "edited text")
        XCTAssertNotEqual(store.clips.first?.contentHash, "h1")
    }

    func testMoveClipToPinboard() {
        store.createPinboard(name: "Engineering")
        let boardId = store.pinboards.first!.id

        let clip = Clip(type: .text, textContent: "code", contentHash: "h1")
        store.clips.append(clip)
        context.insert(clip)

        store.moveClipToPinboard(clip, pinboardId: boardId)
        XCTAssertEqual(store.clips.first?.pinboardId, boardId)

        store.moveClipToPinboard(clip, pinboardId: nil)
        XCTAssertNil(store.clips.first?.pinboardId)
    }
}
