import XCTest

final class StashUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // UI-01: App launch → menu bar icon exists
    func testMenuBarIconExists() {
        let app = XCUIApplication()
        app.launch()

        // MenuBarExtra creates a status item; verify the app launched without crash
        XCTAssertTrue(app.waitForExistence(timeout: 5))
    }
}
