import XCTest
@testable import Stash

final class ColorParserTests: XCTestCase {

    // U-16: #F4A261 → ClipType.color, RGB=(244,162,97)
    func testParseHexColor() {
        let result = ColorParser.parse("#F4A261")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.hex, "#F4A261")
        XCTAssertEqual(result?.rgb, "244,162,97")
    }

    // U-17: rgb(36, 70, 83) → ClipType.color
    func testParseRGBColor() {
        let result = ColorParser.parse("rgb(36, 70, 83)")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rgb, "36,70,83")
        XCTAssertNotNil(result?.hex)
    }

    func testParseHexWithoutHash() {
        let result = ColorParser.parse("FF0000")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.hex, "#FF0000")
    }

    func testParseInvalidColor() {
        XCTAssertNil(ColorParser.parse("hello world"))
        XCTAssertNil(ColorParser.parse("#GGGGGG"))
        XCTAssertNil(ColorParser.parse("rgb(999, 0, 0)"))
    }
}
