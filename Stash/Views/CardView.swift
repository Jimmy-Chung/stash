import SwiftUI

struct CardView: View {
    let clip: Clip
    let isSelected: Bool
    let index: Int
    var searchQuery: String = ""

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        VStack(spacing: 0) {
            cardBody
            cardFooter
        }
        .frame(width: 248, height: 320)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected ? accentColor.opacity(0.55) : Color.white.opacity(0.1),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .shadow(color: isSelected ? accentColor.opacity(0.35) : .clear, radius: isSelected ? 8 : 0)
        .offset(y: isSelected ? -6 : 0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    @ViewBuilder
    private var cardBody: some View {
        switch clip.type {
        case .text: textBody
        case .image: imageBody
        case .link: linkBody
        case .rtf: textBody
        case .html: textBody
        case .file: fileBody
        case .color: colorBody
        case .code: codeBody
        case .address: addressBody
        }
    }

    private var textBody: some View {
        Text(searchQuery.isEmpty ? AttributedString(clip.textContent ?? "") : SearchService.highlight(clip.textContent ?? "", query: searchQuery))
            .font(.system(size: 13.5))
            .lineSpacing(1.55)
            .foregroundColor(.white.opacity(0.92))
            .lineLimit(8)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
    }

    private var imageBody: some View {
        VStack(spacing: 10) {
            Group {
                if let imagePath = clip.imagePath,
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 9))

            if let colors = clip.dominantColors, !colors.isEmpty {
                HStack(spacing: 4) {
                    ForEach(colors.prefix(4), id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex) ?? .gray)
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var linkBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 30/255, green: 41/255, blue: 59/255), Color(red: 15/255, green: 23/255, blue: 42/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)

                HStack(spacing: 8) {
                    if let faviconPath = clip.faviconPath,
                       let nsImage = NSImage(contentsOfFile: faviconPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if let url = URL(string: clip.textContent ?? ""), let host = url.host {
                        Text(String(host.prefix(1).uppercased()))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                }
            }

            Text(clip.title ?? clip.textContent ?? "")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            if let url = URL(string: clip.textContent ?? ""), let host = url.host {
                Text(host)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.56))
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fileBody: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.system(size: 42))
                .foregroundColor(accentColor.opacity(0.7))

            Text(clip.fileName ?? "Unknown File")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let path = clip.textContent {
                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
    }

    private var colorBody: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: clip.colorHex ?? "#888888") ?? .gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 18)

            VStack(spacing: 4) {
                Text(clip.colorHex ?? "")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                if let rgb = clip.colorRGB {
                    Text("RGB(\(rgb))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var codeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let lang = clip.codeLanguage {
                HStack {
                    Text(lang)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.15))
                        .clipShape(Capsule())
                    Spacer()
                }
            }

            ScrollView {
                Text(clip.textContent ?? "")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addressBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 28))
                .foregroundColor(accentColor.opacity(0.7))

            Text(clip.textContent ?? "")
                .font(.system(size: 13.5))
                .lineSpacing(1.55)
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
    }

    private var cardFooter: some View {
        HStack(spacing: 8) {
            if let app = clip.sourceApp {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                    Text(app)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Spacer()

            Text(clip.createdAt, style: .relative)
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.6))
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
