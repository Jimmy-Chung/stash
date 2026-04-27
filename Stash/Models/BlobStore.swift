import Foundation

final class BlobStore {
    static let shared = BlobStore()

    let baseDirectory: URL

    init(directory: URL? = nil) {
        if let dir = directory {
            self.baseDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("Stash/Blobs", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
    }

    @discardableResult
    func write(_ data: Data) -> String {
        let fileName = UUID().uuidString + ".png"
        let url = baseDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        return url.path
    }

    func read(path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    func delete(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
