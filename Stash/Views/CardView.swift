import SwiftUI

struct CardView: View {
    let clip: Clip
    let isSelected: Bool
    let index: Int

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
        case .text:
            textBody
        case .image:
            imageBody
        case .link:
            linkBody
        }
    }

    private var textBody: some View {
        Text(clip.textContent ?? "")
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
                    .frame(height: 110)

                if let url = URL(string: clip.textContent ?? ""), let host = url.host {
                    Text(String(host.prefix(1).uppercased()))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }

            if let url = URL(string: clip.textContent ?? ""), let host = url.host {
                Text(host)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.56))
            }

            Text(clip.textContent ?? "")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
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
