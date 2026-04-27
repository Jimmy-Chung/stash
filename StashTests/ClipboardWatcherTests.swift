import XCTest
@testable import Stash

final class ClipboardWatcherTests: XCTestCase {

    // U-10: changeCount unchanged → no callback
    func testNoChangeNoCallback() {
        var count = 5
        let watcher = ClipboardWatcher(changeCountProvider: { count })
        var callCount = 0
        watcher.onCopy = { callCount += 1 }

        watcher.checkForChanges()
        XCTAssertEqual(callCount, 0)
    }

    // U-11: changeCount +1 → callback fires once
    func testChangeCountIncreased() {
        var count = 5
        let watcher = ClipboardWatcher(changeCountProvider: { count })
        var callCount = 0
        watcher.onCopy = { callCount += 1 }

        count = 6
        watcher.checkForChanges()
        XCTAssertEqual(callCount, 1)

        // Second check with same count → no additional call
        watcher.checkForChanges()
        XCTAssertEqual(callCount, 1)
    }
}
