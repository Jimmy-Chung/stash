import XCTest
@testable import Stash

final class DedupeHasherTests: XCTestCase {

    // U-07: same plain text twice → identical hash
    func testSameTextHashIdentical() {
        let h1 = DedupeHasher.hash(string: "Hello, Stash!")
        let h2 = DedupeHasher.hash(string: "Hello, Stash!")
        XCTAssertEqual(h1, h2)
    }

    // U-08: same image bytes twice → identical hash
    func testSameDataHashIdentical() {
        let data = Data("image-bytes".utf8)
        let h1 = DedupeHasher.hash(data: data)
        let h2 = DedupeHasher.hash(data: data)
        XCTAssertEqual(h1, h2)
    }

    // U-09: different case → different hash (preserve case)
    func testCaseSensitive() {
        let h1 = DedupeHasher.hash(string: "Hello")
        let h2 = DedupeHasher.hash(string: "hello")
        XCTAssertNotEqual(h1, h2)
    }
}
