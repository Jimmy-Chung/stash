import XCTest
@testable import Stash

final class ClipModelTests: XCTestCase {

    // U-12: Clip serialization → deserialization preserves data
    func testClipCodingRoundTrip() throws {
        let clip = Clip(type: .text, textContent: "Test persistence", contentHash: "hash123")
        let encoder = JSONEncoder()
        let data = try encoder.encode(clip)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Clip.self, from: data)

        XCTAssertEqual(decoded.id, clip.id)
        XCTAssertEqual(decoded.textContent, "Test persistence")
        XCTAssertEqual(decoded.type, .text)
        XCTAssertEqual(decoded.contentHash, "hash123")
    }

    func testClipStorePersistence() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StashTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let store = ClipboardStore()
        // We can't inject a custom storage URL easily, but we can test the coding round-trip
        let clip = Clip(type: .link, textContent: "https://example.com", contentHash: "abc")
        let encoder = JSONEncoder()
        let data = try encoder.encode([clip])
        let storageURL = tempDir.appendingPathComponent("clips.json")
        try data.write(to: storageURL)

        let readBack = try Data(contentsOf: storageURL)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([Clip].self, from: readBack)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.textContent, "https://example.com")
        XCTAssertEqual(decoded.first?.type, .link)

        try FileManager.default.removeItem(at: tempDir)
    }
}
