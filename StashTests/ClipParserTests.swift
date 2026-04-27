import XCTest
import AppKit
@testable import Stash

final class ClipParserTests: XCTestCase {

    // U-01: plain text → ClipType.text
    func testParsePlainText() {
        let pb = NSPasteboard.withUniqueName()
        defer { pb.releaseGlobally() }
        pb.clearContents()
        pb.setString("Hello, World!", forType: .string)

        let result = ClipParser.parse(pb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .text)
        XCTAssertEqual(result?.textContent, "Hello, World!")
    }

    // U-02: https URL string → ClipType.link
    func testParseURL() {
        let pb = NSPasteboard.withUniqueName()
        defer { pb.releaseGlobally() }
        pb.clearContents()
        pb.setString("https://example.com/path", forType: .string)
        pb.setString("https://example.com/path", forType: .URL)

        let result = ClipParser.parse(pb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .link)
    }

    // U-03: PNG data → ClipType.image
    func testParsePNG() {
        let pb = NSPasteboard.withUniqueName()
        defer { pb.releaseGlobally() }
        pb.clearContents()

        let image = NSImage(size: NSSize(width: 10, height: 10))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 10, height: 10).fill()
        image.unlockFocus()

        if let tiffData = image.tiffRepresentation {
            pb.setData(tiffData, forType: .tiff)
        }

        let result = ClipParser.parse(pb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .image)
        XCTAssertNotNil(result?.imageData)
    }

    // U-04: empty pasteboard → nil
    func testEmptyPasteboard() {
        let pb = NSPasteboard.withUniqueName()
        defer { pb.releaseGlobally() }
        pb.clearContents()

        let result = ClipParser.parse(pb)
        XCTAssertNil(result)
    }
}
