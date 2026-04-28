import XCTest
import SwiftData
@testable import Stash

@MainActor
final class ClipModelTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Clip.self, Pinboard.self, configurations: config)
        context = modelContainer.mainContext
    }

    // U-12: Clip creation preserves data
    func testClipCreationPreservesData() {
        let clip = Clip(type: .text, textContent: "Test persistence", contentHash: "hash123")
        context.insert(clip)

        XCTAssertEqual(clip.textContent, "Test persistence")
        XCTAssertEqual(clip.type, .text)
        XCTAssertEqual(clip.contentHash, "hash123")
        XCTAssertNotNil(clip.id)
        XCTAssertNotNil(clip.createdAt)
    }

    func testClipStorePersistence() throws {
        let store = ClipboardStore(modelContext: context)
        let clip = Clip(type: .link, textContent: "https://example.com", contentHash: "abc")
        store.clips.append(clip)
        context.insert(clip)

        try context.save()

        let descriptor = FetchDescriptor<Clip>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.textContent, "https://example.com")
        XCTAssertEqual(fetched.first?.type, .link)
    }

    func testDisplayTitleForLink() {
        let clip = Clip(type: .link, textContent: "https://example.com/path", contentHash: "h1")
        XCTAssertEqual(clip.displayTitle, "example.com")
    }

    func testDisplayTitleForCode() {
        let clip = Clip(type: .code, textContent: "print('hi')", contentHash: "h2", codeLanguage: "Python")
        XCTAssertEqual(clip.displayTitle, "Python")
    }

    func testDisplayTitleTruncatesLongText() {
        let longText = String(repeating: "a", count: 100)
        let clip = Clip(type: .text, textContent: longText, contentHash: "h3")
        XCTAssertEqual(clip.displayTitle.count, 60)
    }
}
