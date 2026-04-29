import XCTest
import SwiftData
@testable import Stash

@MainActor
final class CardDisplayTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var context: ModelContext!
    private var store: ClipboardStore!

    override func setUp() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Clip.self, Pinboard.self, configurations: config)
        context = modelContainer.mainContext
        store = ClipboardStore(modelContext: context)
    }

    // U-41: Card display should not contain seconds/minutes time text
    func testCardNoSecondsMinutesDisplay() {
        let clip = Clip(type: .text, textContent: "hello world", contentHash: "h1")
        let title = clip.displayTitle
        // displayTitle should not contain time-group labels like "Just now", "Today", etc.
        XCTAssertFalse(title.contains("Just now"))
        XCTAssertFalse(title.contains("Yesterday"))
    }

    // U-42: Card display should not contain date text
    func testCardNoDateDisplay() {
        let clip = Clip(type: .text, textContent: "hello world", contentHash: "h1")
        let title = clip.displayTitle
        // displayTitle should be plain content, no date formatting
        XCTAssertFalse(title.contains("2026"))
        XCTAssertFalse(title.contains("Apr"))
        XCTAssertFalse(title.contains("Monday"))
    }
}
