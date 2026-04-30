import Foundation
import AppKit

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

    func write(_ data: Data) -> String? {
        let fileName = UUID().uuidString + ".png"
        let url = baseDirectory.appendingPathComponent(fileName)
        do {
            var finalData = data
            if data.count > 102_400,
               let image = NSImage(data: data),
               let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let jpeg = bitmap.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [.compressionFactor: 0.8]) {
                finalData = jpeg
            }
            try finalData.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    func read(path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    func delete(_ path: String) {
        let resolved = URL(fileURLWithPath: path).standardized
        guard resolved.path.hasPrefix(baseDirectory.standardized.path) else { return }
        try? FileManager.default.removeItem(at: resolved)
    }
}
