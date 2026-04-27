import XCTest
@testable import Stash

final class BlobStoreTests: XCTestCase {

    // U-05: write PNG → read back identical bytes
    func testWriteAndRead() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StashTest-\(UUID().uuidString)")
        let store = BlobStore(directory: tempDir)

        let data = Data("fake png data for test".utf8)
        let path = store.write(data)

        let readBack = store.read(path: path)
        XCTAssertEqual(data, readBack)

        try? FileManager.default.removeItem(at: tempDir)
    }

    // U-06: delete Clip → associated Blob deleted
    func testDeleteRemovesBlob() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StashTest-\(UUID().uuidString)")
        let store = BlobStore(directory: tempDir)

        let data = Data("test".utf8)
        let path = store.write(data)

        store.delete(path)
        let readBack = store.read(path: path)
        XCTAssertNil(readBack)

        try? FileManager.default.removeItem(at: tempDir)
    }
}
