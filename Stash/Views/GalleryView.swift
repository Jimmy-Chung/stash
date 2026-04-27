import SwiftUI

struct GalleryView: View {
    @ObservedObject var store: ClipboardStore
    var onPaste: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if store.clips.isEmpty {
                emptyState
            } else {
                cardGallery
            }
            footer
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
    }

    private var cardGallery: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(store.clips.enumerated()), id: \.element.id) { index, clip in
                        CardView(clip: clip, isSelected: index == store.selectedIndex, index: index)
                            .id(index)
                            .onTapGesture {
                                store.selectedIndex = index
                            }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
            .onChange(of: store.selectedIndex) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(store.selectedIndex, anchor: .center)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No clips yet")
                .font(.system(size: 13.5))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 14) {
                footerHint("\u{2190} \u{2192}", "Navigate")
                footerHint("\u{2318}1-9", "Quick Paste")
            }
            .font(.system(size: 11.5))

            Spacer()

            Text("\(store.clips.count) clips")
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.55))
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .padding(.bottom, 12)
    }

    private func footerHint(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(keys)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
            Text(label)
                .foregroundColor(.white.opacity(0.55))
        }
    }
}
