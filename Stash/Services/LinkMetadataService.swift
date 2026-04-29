import Foundation
import LinkPresentation
import UniformTypeIdentifiers

final class LinkMetadataService {
    static let shared = LinkMetadataService()

    private let provider = LPMetadataProvider()

    func fetchMetadata(for urlString: String, completion: @escaping (LinkMeta?) -> Void) {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              (scheme == "http" || scheme == "https"),
              url.host != nil,
              urlString.count <= 2048 else {
            completion(nil)
            return
        }

        do {
            try OBJCExceptionCatcher.`try`({
                self.provider.startFetchingMetadata(for: url) { metadata, error in
                    guard error == nil, let metadata = metadata else {
                        completion(nil)
                        return
                    }

                    var faviconPath: String?

                    if let iconProvider = metadata.iconProvider {
                        let semaphore = DispatchSemaphore(value: 0)
                        iconProvider.loadItem(forTypeIdentifier: UTType.ico.identifier, options: nil) { data, _ in
                            if let data = data as? Data {
                                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                                let faviconDir = appSupport.appendingPathComponent("Stash/Favicons", isDirectory: true)
                                try? FileManager.default.createDirectory(at: faviconDir, withIntermediateDirectories: true)
                                let path = faviconDir.appendingPathComponent("\(url.host ?? UUID().uuidString).ico")
                                try? data.write(to: path, options: .atomicWrite)
                                faviconPath = path.path
                            }
                            semaphore.signal()
                        }
                        semaphore.wait()
                    }

                    let result = LinkMeta(
                        title: metadata.title,
                        faviconPath: faviconPath
                    )
                    completion(result)
                }
            })
        } catch {
            print("LinkMetadata fetch failed: \(error)")
            completion(nil)
        }
    }

    struct LinkMeta {
        let title: String?
        let faviconPath: String?
    }
}
