import SwiftUI

struct GalleryView: View {
    @ObservedObject var store: ClipboardStore
    var onPaste: () -> Void
    var onClose: () -> Void
    var onPlainPaste: (() -> Void)?

    @State private var isQuickLooking = false
    @State private var editingClip: Clip?
    @State private var showDeleteConfirmation = false
    @State private var clipToDelete: Clip?

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store)

            Divider()
                .background(Color.white.opacity(0.1))

            VStack(spacing: 0) {
                searchBar
                filterBar
                if store.displayClips.isEmpty {
                    emptyState
                } else {
                    cardGallery
                }
                footer
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .sheet(isPresented: $isQuickLooking) {
            quickLookView
        }
        .sheet(item: $editingClip) { clip in
            EditClipView(clip: clip, store: store)
        }
        .alert("Delete Pinned Item?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { clipToDelete = nil }
            Button("Delete", role: .destructive) {
                if let clip = clipToDelete {
                    store.deleteClip(clip)
                    clipToDelete = nil
                }
            }
        } message: {
            Text("This item is pinned. Are you sure you want to delete it?")
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashToggleQuickLook)) { _ in
            isQuickLooking.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashDeleteClip)) { notification in
            if let clip = notification.object as? Clip {
                if clip.isPinned {
                    clipToDelete = clip
                    showDeleteConfirmation = true
                } else {
                    store.deleteClip(clip)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashTogglePin)) { _ in
            if let clip = store.clip(at: store.selectedIndex) {
                store.togglePin(clip)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashEditClip)) { _ in
            if let clip = store.clip(at: store.selectedIndex) {
                editingClip = clip
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            TextField("Search clips...", text: Binding(
                get: { store.searchText },
                set: { store.updateSearch($0) }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(.white)

            if !store.searchText.isEmpty {
                Button(action: { store.clearSearch() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
    }

    // MARK: - Filter Capsules

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterCapsule(label: "All", type: nil)
                Divider().frame(height: 16).padding(.horizontal, 2)
                ForEach(ClipType.allCases, id: \.self) { type in
                    filterCapsule(label: type.displayName, type: type)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
    }

    private func filterCapsule(label: String, type: ClipType?) -> some View {
        let isActive = store.filterType == type
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                store.filterType = type
                store.selectedIndex = 0
            }
        }) {
            HStack(spacing: 4) {
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? accentColor.opacity(0.25) : Color.white.opacity(0.06))
            .foregroundColor(isActive ? accentColor : .white.opacity(0.6))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Gallery with Time Groups

    private var cardGallery: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    let groups = TimeGrouper.groupClips(store.displayClips)
                    ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.0.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.leading, 8)

                            HStack(spacing: 14) {
                                ForEach(Array(group.1.enumerated()), id: \.element.id) { _, clip in
                                    let globalIdx = store.displayClips.firstIndex(where: { $0.id == clip.id }) ?? 0
                                    CardView(
                                        clip: clip,
                                        isSelected: globalIdx == store.selectedIndex,
                                        index: globalIdx,
                                        searchQuery: store.searchText
                                    )
                                    .id(globalIdx)
                                    .onTapGesture {
                                        store.selectedIndex = globalIdx
                                    }
                                    .contextMenu {
                                        ClipContextMenu(
                                            clip: clip,
                                            store: store,
                                            onPaste: onPaste,
                                            onEdit: { editingClip = clip }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
            }
            .onChange(of: store.selectedIndex) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(store.selectedIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: store.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.3))
            Text(store.searchText.isEmpty ? "No clips yet" : "No matches found")
                .font(.system(size: 13.5))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    // MARK: - Quick Look

    private var quickLookView: some View {
        VStack(spacing: 0) {
            if let clip = store.clip(at: store.selectedIndex) {
                switch clip.type {
                case .image:
                    if let path = clip.imagePath, let nsImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 600, maxHeight: 500)
                    }
                default:
                    ScrollView {
                        Text(clip.textContent ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(maxWidth: 500, maxHeight: 400)
                }

                HStack {
                    Text(clip.displayTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Button("Close") { isQuickLooking = false }
                        .buttonStyle(.plain)
                        .foregroundColor(accentColor)
                }
                .padding()
            }
        }
        .background(Color(red: 15/255, green: 23/255, blue: 42/255))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            HStack(spacing: 14) {
                footerHint("\u{2190} \u{2192}", "Navigate")
                footerHint("\u{2318}1-9", "Quick Paste")
                footerHint("Space", "Preview")
                footerHint("\u{2318}P", "Pin")
            }
            .font(.system(size: 11.5))

            Spacer()

            Text("\(store.displayClips.count) clips")
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
