import Foundation

enum ColorParser {
    struct ParsedColor {
        let hex: String
        let rgb: String
    }

    static func parse(_ text: String) -> ParsedColor? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let color = parseHex(trimmed) { return color }
        if let color = parseRGB(trimmed) { return color }
        if let color = parseOKLCH(trimmed) { return color }

        return nil
    }

    private static func parseHex(_ text: String) -> ParsedColor? {
        let pattern = #"^#?([0-9a-fA-F]{6})$"#
        guard let match = text.range(of: pattern, options: .regularExpression) else { return nil }
        let hexStr = String(text[match]).replacingOccurrences(of: "#", with: "")
        guard hexStr.count == 6 else { return nil }

        let r = Int(hexStr.prefix(2), radix: 16) ?? 0
        let g = Int(hexStr.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = Int(hexStr.dropFirst(4).prefix(2), radix: 16) ?? 0

        return ParsedColor(hex: "#\(hexStr.uppercased())", rgb: "\(r),\(g),\(b)")
    }

    private static func parseRGB(_ text: String) -> ParsedColor? {
        let pattern = #"^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }

        func extract(_ idx: Int) -> Int? {
            guard let range = Range(match.range(at: idx), in: text) else { return nil }
            return Int(text[range])
        }

        guard let r = extract(1), let g = extract(2), let b = extract(3),
              (0...255).contains(r), (0...255).contains(g), (0...255).contains(b) else { return nil }

        let hex = String(format: "#%02X%02X%02X", r, g, b)
        return ParsedColor(hex: hex, rgb: "\(r),\(g),\(b)")
    }

    private static func parseOKLCH(_ text: String) -> ParsedColor? {
        let pattern = #"^oklch\(\s*([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }

        func extract(_ idx: Int) -> Double? {
            guard let range = Range(match.range(at: idx), in: text) else { return nil }
            return Double(text[range])
        }

        guard let l = extract(1), let c = extract(2), let h = extract(3) else { return nil }

        // oklch → sRGB approximation
        let a = c * cos(h * .pi / 180)
        let bVal = c * sin(h * .pi / 180)
        let (r, g, bl) = oklabToSRGB(l: l, a: a, b: bVal)

        let ri = clamp(Int(r * 255))
        let gi = clamp(Int(g * 255))
        let bi = clamp(Int(bl * 255))

        let hex = String(format: "#%02X%02X%02X", ri, gi, bi)
        return ParsedColor(hex: hex, rgb: "\(ri),\(gi),\(bi)")
    }

    private static func oklabToSRGB(l: Double, a: Double, b: Double) -> (Double, Double, Double) {
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let l3 = l_ * l_ * l_
        let m3 = m_ * m_ * m_
        let s3 = s_ * s_ * s_

        let r = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bl = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        return (r, g, bl)
    }

    private static func clamp(_ v: Int) -> Int {
        max(0, min(255, v))
    }
}
