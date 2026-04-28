import XCTest
@testable import Stash

final class PreferencesTests: XCTestCase {

    func testDefaultValues() {
        UserDefaults.standard.removeObject(forKey: "historyLimit")
        UserDefaults.standard.removeObject(forKey: "blurAmount")
        UserDefaults.standard.removeObject(forKey: "showMenuBarIcon")
        UserDefaults.standard.removeObject(forKey: "autoHideOnFocusLoss")
        let prefs = PreferencesStore()
        XCTAssertEqual(prefs.historyLimit, 500)
        XCTAssertEqual(prefs.blurAmount, 50.0)
        XCTAssertTrue(prefs.showMenuBarIcon)
        XCTAssertTrue(prefs.autoHideOnFocusLoss)
    }

    func testCardDensitySizes() {
        // BUG-015: cards are now 1:1 aspect ratio
        XCTAssertEqual(PreferencesStore.CardDensity.compact.cardWidth, 240)
        XCTAssertEqual(PreferencesStore.CardDensity.normal.cardWidth, 268)
        XCTAssertEqual(PreferencesStore.CardDensity.cozy.cardWidth, 290)

        XCTAssertEqual(PreferencesStore.CardDensity.compact.cardHeight, 240)
        XCTAssertEqual(PreferencesStore.CardDensity.normal.cardHeight, 268)
        XCTAssertEqual(PreferencesStore.CardDensity.cozy.cardHeight, 290)
    }

    func testAppearanceModes() {
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 0), .system)
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 1), .light)
        XCTAssertEqual(PreferencesStore.AppearanceMode(rawValue: 2), .dark)
    }
}
