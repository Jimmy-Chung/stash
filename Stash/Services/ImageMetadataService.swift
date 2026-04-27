import Foundation
import CoreImage
import AppKit

enum ImageMetadataService {
    struct ImageMeta {
        let width: Int
        let height: Int
        let dominantColors: [String]
    }

    static func extract(from data: Data) -> ImageMeta? {
        guard let nsImage = NSImage(data: data) else { return nil }

        let width = Int(nsImage.size.width)
        let height = Int(nsImage.size.height)

        let colors = extractDominantColors(from: data)

        return ImageMeta(width: width, height: height, dominantColors: colors)
    }

    private static func extractDominantColors(from data: Data, count: Int = 4) -> [String] {
        guard let ciImage = CIImage(data: data) else { return [] }

        // Resize to small for faster color sampling
        let scale = min(64.0 / ciImage.extent.width, 64.0 / ciImage.extent.height, 1.0)
        let scaledWidth = ciImage.extent.width * scale
        let scaledHeight = ciImage.extent.height * scale

        guard let filter = CIFilter(name: "CIAffineTransform") else { return [] }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let transform = NSAffineTransform()
        transform.scale(by: scale)
        filter.setValue(transform, forKey: kCIInputTransformKey)

        guard let outputImage = filter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)) else { return [] }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        var colorCounts: [String: Int] = [:]
        let step = max(1, Int(scaledWidth) / 8)

        for x in stride(from: 0, to: Int(scaledWidth), by: step) {
            for y in stride(from: 0, to: Int(scaledHeight), by: step) {
                guard let color = bitmapRep.colorAt(x: x, y: y) else { continue }
                let r = Int(color.redComponent * 255)
                let g = Int(color.greenComponent * 255)
                let b = Int(color.blueComponent * 255)

                // Skip near-black and near-white
                if (r + g + b) < 30 || (r + g + b) > 720 { continue }
                // Skip very transparent
                if color.alphaComponent < 0.3 { continue }

                // Quantize to reduce noise
                let qr = (r / 32) * 32
                let qg = (g / 32) * 32
                let qb = (b / 32) * 32
                let key = String(format: "#%02X%02X%02X", qr, qg, qb)
                colorCounts[key, default: 0] += 1
            }
        }

        return colorCounts.sorted { $0.value > $1.value }
            .prefix(count)
            .map { $0.key }
    }
}
