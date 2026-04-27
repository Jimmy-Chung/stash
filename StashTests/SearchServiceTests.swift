import XCTest
@testable import Stash

final class SearchServiceTests: XCTestCase {

    // U-23: search "hello" matches title/content/app
    func testSearchMatchesMultipleFields() {
        let clips = [
            Clip(type: .text, textContent: "Hello World", sourceApp: "Notes", contentHash: "h1"),
            Clip(type: .text, textContent: "Goodbye", sourceApp: "Safari", contentHash: "h2"),
            Clip(type: .text, textContent: "Say hello back", sourceApp: "Terminal", contentHash: "h3"),
        ]

        let results = SearchService.filter(clips: clips, query: "hello")
        XCTAssertEqual(results.count, 2)
    }

    // U-24: empty search returns all
    func testEmptySearchReturnsAll() {
        let clips = [
            Clip(type: .text, textContent: "abc", contentHash: "h1"),
            Clip(type: .text, textContent: "def", contentHash: "h2"),
        ]

        let results = SearchService.filter(clips: clips, query: "")
        XCTAssertEqual(results.count, 2)

        let results2 = SearchService.filter(clips: clips, query: "   ")
        XCTAssertEqual(results2.count, 2)
    }

    func testFilterByType() {
        let clips = [
            Clip(type: .text, textContent: "text", contentHash: "h1"),
            Clip(type: .image, contentHash: "h2"),
            Clip(type: .link, textContent: "https://example.com", contentHash: "h3"),
        ]

        let textOnly = SearchService.filter(clips: clips, type: .text)
        XCTAssertEqual(textOnly.count, 1)
        XCTAssertEqual(textOnly.first?.type, .text)

        let all = SearchService.filter(clips: clips, type: nil)
        XCTAssertEqual(all.count, 3)
    }

    func testHighlightProducesAttributedString() {
        let result = SearchService.highlight("Hello World Hello", query: "hello")
        // Verify it produces an AttributedString without crashing
        XCTAssertEqual(String(result.characters.prefix(5)), "Hello")
    }
}
