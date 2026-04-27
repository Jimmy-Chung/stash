import Foundation
import AppKit

enum AddressDetector {
    static func detect(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.address.rawValue) else { return nil }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: range)

        guard let match = matches.first,
              match.resultType == .address,
              let range = Range(match.range, in: text) else { return nil }

        return String(text[range])
    }

    static func containsAddress(_ text: String) -> Bool {
        return detect(in: text) != nil
    }
}
