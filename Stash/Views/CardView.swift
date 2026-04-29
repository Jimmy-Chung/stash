import SwiftUI
import AppKit

struct CardView: View {
    let clip: Clip
    let isSelected: Bool
    let index: Int
    var searchQuery: String = ""
    var cardSize: CGFloat = 268  // 默认值，由父视图传入
    var pinColor: Color? = nil   // Color of the pinboard the clip is pinned to.

    @State private var isHovered = false
    @State private var appeared = false

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    private var footerHeight: CGFloat { 38 }

    var body: some View {
        VStack(spacing: 0) {
            cardBody
                .frame(width: cardSize, height: cardSize - footerHeight)
                .clipped()
            cardFooter
                .frame(width: cardSize, height: footerHeight)
                .background(Color.black.opacity(0.18))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 0.5),
                    alignment: .top
                )
                .clipped()
        }
        .frame(width: cardSize, height: cardSize)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(cardBorder, lineWidth: isSelected ? 2 : 0.5)
        )
        .shadow(color: cardShadow, radius: cardShadowRadius, y: cardShadowY)
        .offset(y: cardOffsetY)
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.22), value: isSelected)
        .animation(.easeInOut(duration: 0.22), value: isHovered)
        .animation(.easeOut(duration: 0.36), value: appeared)
        .overlay(alignment: .topTrailing) {
            if pinColor != nil {
                pinnedBadge
            }
        }
        .overlay(alignment: .topLeading) {
            if (isSelected || isHovered) && index < 9 {
                shortcutOverlay
            }
        }
        .onDrag {
            NSItemProvider(object: clip.id.uuidString as NSString)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .onAppear {
            appeared = true
        }
    }

    // MARK: - Computed Styles

    private var cardBackground: Color {
        if isSelected { return Color.white.opacity(0.13) }
        if isHovered { return Color.white.opacity(0.10) }
        return Color.white.opacity(0.07)
    }

    private var cardBorder: Color {
        if isSelected { return accentColor.opacity(0.55) }
        if isHovered { return Color.white.opacity(0.16) }
        return Color.white.opacity(0.1)
    }

    private var cardShadow: Color {
        if isSelected { return accentColor.opacity(0.35) }
        if isHovered { return Color.black.opacity(0.4) }
        return .clear
    }

    private var cardShadowRadius: CGFloat {
        isSelected ? 12 : isHovered ? 16 : 0
    }

    private var cardShadowY: CGFloat {
        isSelected ? 10 : isHovered ? 8 : 0
    }

    private var cardOffsetY: CGFloat {
        isSelected ? -6 : isHovered ? -3 : 0
    }

    // MARK: - Pinned Badge (CSS .card.pinned::before)

    private var pinnedBadge: some View {
        let color = pinColor ?? accentColor
        return ZStack {
            Circle()
                .fill(color.opacity(0.95))
                .frame(width: 18, height: 18)
                .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            Image(systemName: "pin.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(10)
    }

    // MARK: - Shortcut Overlay (CSS .card-shortcut)

    private var shortcutOverlay: some View {
        HStack(spacing: 1) {
            Text("\u{2318}")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
            Text("\(index + 1)")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
        }
        .foregroundColor(.white.opacity(0.95))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .padding(10)
        .transition(.opacity)
    }

    // MARK: - Card Body

    @ViewBuilder
    private var cardBody: some View {
        switch clip.type {
        case .text: textBody
        case .image: imageBody
        case .link: linkBody
        case .rtf: textBody
        case .file: fileBody
        case .color: colorBody
        case .code: codeBody
        }
    }

    // MARK: - Text (CSS .cb-text with mask-image fade)

    private var textBody: some View {
        ZStack(alignment: .bottom) {
            Text(searchQuery.isEmpty
                ? AttributedString(clip.textContent ?? "")
                : SearchService.highlight(clip.textContent ?? "", query: searchQuery))
                .font(.system(size: 13.5))
                .lineSpacing(1.55)
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))

            LinearGradient(
                colors: [.clear, Color(red: 20/255, green: 20/255, blue: 24/255)],
                startPoint: UnitPoint(x: 0.5, y: 0.55),
                endPoint: .bottom
            )
            .frame(height: 60)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Image (CSS .cb-image)

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
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0x26/255, green: 0x46/255, blue: 0x53/255),
                                         Color(red: 0x2a/255, green: 0x9d/255, blue: 0x8f/255),
                                         Color(red: 0xe9/255, green: 0xc4/255, blue: 0x6a/255),
                                         Color(red: 0xf4/255, green: 0xa2/255, blue: 0x61/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), .clear],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 9))

            HStack {
                if let colors = clip.dominantColors, !colors.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(colors.prefix(4), id: \.self) { hex in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                    }
                }
                Spacer()
                if let w = clip.imageWidth, let h = clip.imageHeight {
                    Text("\(w)\u{00D7}\(h)")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .monospacedDigit()
                }
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Link (CSS .cb-link with thumb glow)

    private var linkBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 30/255, green: 41/255, blue: 59/255),
                                     Color(red: 15/255, green: 23/255, blue: 42/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
                    .overlay(
                        RadialGradient(
                            colors: [accentColor.opacity(0.35), .clear],
                            center: UnitPoint(x: 0.7, y: 0.2),
                            startRadius: 0,
                            endRadius: 80
                        )
                    )

                HStack(spacing: 8) {
                    if let faviconPath = clip.faviconPath,
                       let nsImage = NSImage(contentsOfFile: faviconPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
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

    // MARK: - File (CSS .cb-file with red icon + corner fold)

    private var fileBody: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0xef/255, green: 0x44/255, blue: 0x44/255),
                                     Color(red: 0xb9/255, green: 0x1c/255, blue: 0x1c/255)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 80)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .overlay(
                        Group {
                            if let ext = clip.fileName?.components(separatedBy: ".").last?.uppercased() {
                                Text(ext)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(0.5)
                            }
                        }
                    )

                // Corner fold
                Path { p in
                    p.move(to: CGPoint(x: 64 - 18, y: 0))
                    p.addLine(to: CGPoint(x: 64, y: 0))
                    p.addLine(to: CGPoint(x: 64, y: 18))
                    p.closeSubpath()
                }
                .fill(Color.white.opacity(0.25))
                .frame(width: 64, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(clip.fileName ?? "Unknown File")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
    }

    // MARK: - Color (CSS .cb-color with swatch + hex + meta grid)

    private var colorBody: some View {
        VStack(spacing: 12) {
            let hexColor = Color(hex: clip.colorHex ?? "#888888") ?? .gray
            RoundedRectangle(cornerRadius: 9)
                .fill(hexColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .overlay(alignment: .bottomLeading) {
                    Text(clip.colorHex ?? "")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.42))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

            if let rgb = clip.colorRGB {
                let parts = rgb.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                HStack(spacing: 10) {
                    if parts.count >= 3 {
                        colorMetaLabel("R", parts[0])
                        colorMetaLabel("G", parts[1])
                        colorMetaLabel("B", parts[2])
                    }
                }
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 16)
            }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func colorMetaLabel(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(.white.opacity(0.42))
            Text(value)
                .foregroundColor(.white.opacity(0.62))
        }
    }

    // MARK: - Code (CSS .cb-code with blue lang badge + mask fade)

    private var codeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let lang = clip.codeLanguage {
                Text(lang.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.04)
                    .foregroundColor(Color(red: 0x93/255, green: 0xc5/255, blue: 0xfd/255))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(red: 0x93/255, green: 0xc5/255, blue: 0xfd/255, opacity: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            ZStack(alignment: .bottom) {
                ScrollView {
                    Text(clip.textContent ?? "")
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundColor(Color(red: 0xe2/255, green: 0xe8/255, blue: 0xf0/255))
                        .lineLimit(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LinearGradient(
                    colors: [.clear, Color(red: 20/255, green: 20/255, blue: 24/255)],
                    startPoint: UnitPoint(x: 0.5, y: 0.6),
                    endPoint: .bottom
                )
                .frame(height: 50)
                .allowsHitTesting(false)
            }
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Card Footer (app icon + relative timestamp)

    private var cardFooter: some View {
        HStack(spacing: 8) {
            if let app = clip.sourceApp {
                HStack(spacing: 5) {
                    Image(nsImage: appIcon(for: app))
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text(app)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(relativeTimeString(for: clip.createdAt))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func appIcon(for appName: String) -> NSImage {
        for app in NSWorkspace.shared.runningApplications {
            if app.localizedName == appName, let icon = app.icon {
                return icon
            }
        }
        let path = "/Applications/\(appName).app"
        if FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        let systemPath = "/System/Applications/\(appName).app"
        if FileManager.default.fileExists(atPath: systemPath) {
            return NSWorkspace.shared.icon(forFile: systemPath)
        }
        return NSWorkspace.shared.icon(forFileType: "public.generic-application")
    }

    private func relativeTimeString(for date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let interval = now.timeIntervalSince(date)

        if calendar.isDateInToday(date) {
            if interval < 60 { return "刚刚" }
            if interval < 3600 {
                let mins = Int(interval / 60)
                return "\(mins)分钟前"
            }
            let hours = Int(interval / 3600)
            let remainingMins = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if remainingMins > 0 {
                return "\(hours)小时\(remainingMins)分钟前"
            }
            return "\(hours)小时前"
        }

        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if days == 1 { return "1天前" }
        return "\(days)天前"
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
