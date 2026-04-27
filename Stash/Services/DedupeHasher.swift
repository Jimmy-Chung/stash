import Foundation
import CryptoKit

enum DedupeHasher {
    static func hash(data: Data) -> String {
        let digest = CryptoKit.SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func hash(string: String) -> String {
        hash(data: Data(string.utf8))
    }
}
