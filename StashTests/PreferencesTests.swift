import XCTest
@testable import Stash

final class PreferencesTests: XCTestCase {

    func testDefaultValues() {
        let prefs = PreferencesStore()
        XCTAssertEqual(prefs.historyLimit, 500)
        XCTAssertEqual(prefs.blurAmount, 50.0)
        XCTAssertTrue(prefs.showMenuBarIcon)
        XCTAssertTrue(prefs.autoHideOnFocusLoss)
    }

    func testCardDensitySizes() {
        XCTAssertEqual(PreferencesStore.CardDensity.compact.cardWidth, 200)
        XCTAssertEqual(PreferencesStore.CardDensity.normal.cardWidth, 248)
        XCTAssertEqual(PreferencesStore.CardDensity.cozy.cardWidth, 300)

        XCTAssertEqual(PreferencesStore.CardDensity.compact.cardHeight, 260)
        XCTAssertEqual(PreferencesStore.CardDensity.normal.cardHeight, 320)
        XCTAssertEqual(PreferencesStore.CardDensity.cozy.cardHeight, 400)
    }

    func testAppearanceModes() {
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 0), .system)
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 1), .light)
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 2), .dark)
    }
}
