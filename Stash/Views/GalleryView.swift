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
    @ObservedObject private var prefs = PreferencesStore.shared

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 0.5)

            VStack(spacing: 0) {
                header
                if store.displayClips.isEmpty {
                    emptyState
                } else {
                    carouselSection
                }
                galleryFooter
            }
        }
        .background(
            ZStack {
                wallpaperGradient
                Color(red: 28/255, green: 28/255, blue: 32/255).opacity(0.35)
                    .background(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.55), radius: 40, y: 24)
        .overlay(
            // Inset top highlight (CSS inset 0 1px 0 rgba(255,255,255,0.08))
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                .mask(
                    Rectangle()
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
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
                    DispatchQueue.main.async {
                        store.deleteClip(clip)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashTogglePin)) { _ in
            if let clip = store.clip(at: store.selectedIndex) {
                DispatchQueue.main.async {
                    store.togglePin(clip)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashEditClip)) { _ in
            if let clip = store.clip(at: store.selectedIndex) {
                editingClip = clip
            }
        }
    }

    // MARK: - Header (CSS .g-header: toolbar + search + pills in one row)

    private var header: some View {
        HStack(spacing: 10) {
            // Toolbar group (CSS .toolbar-group)
            HStack(spacing: 2) {
                toolbarIcon("sidebar.left")
                toolbarIcon("square.grid.2x2")
            }
            .padding(2)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 20)

            // Search wrap (CSS .search-wrap)
            searchField

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 20)

            // Type pills (CSS .type-pills grouped)
            filterPills

            // Settings button
            Button(action: {
                NotificationCenter.default.post(name: .stashOpenPreferences, object: nil)
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.78))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func toolbarIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12))
            .foregroundColor(Color.white.opacity(0.78))
            .frame(width: 28, height: 28)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Search Field (CSS .search-wrap with focus glow)

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))

            TextField("Search clips...", text: Binding(
                get: { store.searchText },
                set: { store.updateSearch($0) }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 13.5))
            .foregroundColor(.white)

            if !store.searchText.isEmpty {
                Button(action: { store.clearSearch() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            } else {
                Text("\u{2318}F")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Filter Pills (CSS .type-pills grouped)

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                filterPill(label: "All", type: nil)
                ForEach(ClipType.allCases, id: \.self) { type in
                    filterPill(label: type.displayName, type: type)
                }
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
        )
    }

    private func filterPill(label: String, type: ClipType?) -> some View {
        let isActive = store.filterType == type
        return Button(action: {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.14)) {
                    store.filterType = type
                    store.selectedIndex = 0
                }
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? .white : .white.opacity(0.62))
                .frame(minWidth: 30)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? Color.white.opacity(0.16) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Carousel (CSS .carousel-wrap with edge fades)

    private var carouselSection: some View {
        ZStack {
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
                                        DispatchQueue.main.async {
                                            store.selectedIndex = globalIdx
                                        }
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
                .padding(.vertical, 18)
            }

            // Edge fades (CSS .carousel-wrap::before/after)
            HStack {
                LinearGradient(
                    colors: [Color(red: 28/255, green: 28/255, blue: 32/255, opacity: 0.55), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 32)
                .allowsHitTesting(false)

                Spacer()

                LinearGradient(
                    colors: [.clear, Color(red: 28/255, green: 28/255, blue: 32/255, opacity: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 32)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(store.searchText.isEmpty ? "\u{1F4CB}" : "\u{1F50D}")
                .font(.system(size: 36))
                .opacity(0.6)
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
                // Header (CSS .pc-head)
                HStack(spacing: 10) {
                    Image(systemName: clip.type.icon)
                        .foregroundColor(accentColor)
                    Text(clip.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5),
                    alignment: .bottom
                )

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
                            .font(.system(size: 14.5))
                            .lineSpacing(1.6)
                            .foregroundColor(.white.opacity(0.92))
                            .padding(22)
                    }
                    .frame(maxWidth: 500, maxHeight: 400)
                }

                // Footer (CSS .pc-foot)
                HStack(spacing: 12) {
                    if let app = clip.sourceApp {
                        Text(app)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text(clip.createdAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Button("Close") { isQuickLooking = false }
                        .buttonStyle(.plain)
                        .foregroundColor(accentColor)
                        .font(.system(size: 12))
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5),
                    alignment: .top
                )
            }
        }
        .background(Color(red: 28/255, green: 28/255, blue: 32/255, opacity: 0.82))
    }

    // MARK: - Gallery Footer (CSS .g-footer with kbd-styled hints)

    private var galleryFooter: some View {
        HStack(spacing: 14) {
            footerKbd("\u{2190}\u{2192}", "Navigate")
            footerKbd("\u{2318}1-9", "Quick Paste")
            footerKbd("Space", "Preview")
            footerKbd("\u{2318}P", "Pin")

            Spacer()

            Text("\(store.displayClips.count) clips")
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.55))
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .padding(.bottom, 12)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: - Wallpaper Theme Gradient

    private var wallpaperGradient: some View {
        Group {
            switch prefs.wallpaperTheme {
            case 1: // Cool
                ZStack {
                    RadialGradient(
                        colors: [Color(red: 0x6c/255, green: 0x8e/255, blue: 0xef/255), .clear],
                        center: UnitPoint(x: 0.18, y: 0.22),
                        startRadius: 0, endRadius: 280
                    )
                    RadialGradient(
                        colors: [Color(red: 0x8b/255, green: 0x5c/255, blue: 0xf6/255), .clear],
                        center: UnitPoint(x: 0.82, y: 0.18),
                        startRadius: 0, endRadius: 260
                    )
                    RadialGradient(
                        colors: [Color(red: 0x06/255, green: 0xb6/255, blue: 0xd4/255), .clear],
                        center: UnitPoint(x: 0.25, y: 0.82),
                        startRadius: 0, endRadius: 280
                    )
                }
                .opacity(0.5)
            case 2: // Mono
                ZStack {
                    RadialGradient(
                        colors: [Color(red: 0x47/255, green: 0x55/255, blue: 0x69/255), .clear],
                        center: UnitPoint(x: 0.30, y: 0.25),
                        startRadius: 0, endRadius: 260
                    )
                    RadialGradient(
                        colors: [Color(red: 0x1e/255, green: 0x29/255, blue: 0x3b/255), .clear],
                        center: UnitPoint(x: 0.75, y: 0.80),
                        startRadius: 0, endRadius: 260
                    )
                }
                .opacity(0.4)
            default: // Warm
                ZStack {
                    RadialGradient(
                        colors: [Color(red: 0xf7/255, green: 0xb2/255, blue: 0x67/255), .clear],
                        center: UnitPoint(x: 0.18, y: 0.22),
                        startRadius: 0, endRadius: 280
                    )
                    RadialGradient(
                        colors: [Color(red: 0xe7/255, green: 0x6f/255, blue: 0x51/255), .clear],
                        center: UnitPoint(x: 0.82, y: 0.18),
                        startRadius: 0, endRadius: 260
                    )
                    RadialGradient(
                        colors: [Color(red: 0x06/255, green: 0xb6/255, blue: 0xd4/255), .clear],
                        center: UnitPoint(x: 0.25, y: 0.82),
                        startRadius: 0, endRadius: 280
                    )
                }
                .opacity(0.45)
            }
        }
        .allowsHitTesting(false)
    }

    private func footerKbd(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(keys)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}
