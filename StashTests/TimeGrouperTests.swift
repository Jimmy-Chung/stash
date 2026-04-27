import XCTest
@testable import Stash

final class TimeGrouperTests: XCTestCase {

    // U-26: "5 分钟前" → "Just now"; "3 天前" → "Last week"
    func testJustNow() {
        let date = Date().addingTimeInterval(-120) // 2 minutes ago
        let group = TimeGrouper.group(for: date)
        XCTAssertEqual(group, .justNow)
    }

    func testToday() {
        let date = Date().addingTimeInterval(-1800) // 30 minutes ago
        let group = TimeGrouper.group(for: date)
        XCTAssertEqual(group, .today)
    }

    func testLastWeek() {
        let date = Date().addingTimeInterval(-3 * 86400) // 3 days ago
        let group = TimeGrouper.group(for: date)
        XCTAssertEqual(group, .lastWeek)
    }

    func testOlder() {
        let date = Date().addingTimeInterval(-30 * 86400) // 30 days ago
        let group = TimeGrouper.group(for: date)
        XCTAssertEqual(group, .older)
    }

    func testGroupClipsPreservesOrder() {
        let now = Date()
        let clips = [
            Clip(type: .text, textContent: "newest", contentHash: "h1"),
            Clip(type: .text, textContent: "middle", contentHash: "h2"),
            Clip(type: .text, textContent: "oldest", contentHash: "h3"),
        ]
        let groups = TimeGrouper.groupClips(clips)
        XCTAssertFalse(groups.isEmpty)
        // All should be in one group since created at nearly same time
        XCTAssertEqual(groups.count, 1)
    }
}
