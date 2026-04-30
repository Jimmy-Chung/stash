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
    @State private var cardSize: CGFloat = 268
    @State private var blurLevel: Int = 1
    @State private var sidebarShowsLabels: Bool = true
    @State private var showPinPicker = false
    @State private var pinPickerIndex = 0

    private let accentColor = Color(red: 120/255, green: 112/255, blue: 242/255)

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store, showsLabels: $sidebarShowsLabels)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .modifier(PanelAppearanceModifier(blurLevel: blurLevel))
        .overlay(alignment: .bottom) {
            if isQuickLooking {
                quickLookView
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .overlay {
            if showPinPicker {
                pinPickerOverlay
            }
        }
        .overlay {
            if let clip = editingClip {
                editOverlay(clip: clip)
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .stashShowPinPicker)) { _ in
            if store.clip(at: store.selectedIndex) != nil {
                pinPickerIndex = 0
                showPinPicker = true
                NotificationCenter.default.post(name: .stashPinPickerStateChanged, object: nil, userInfo: ["visible": true])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashPinPickerUp)) { _ in
            guard showPinPicker else { return }
            let total = pinPickerTotal
            if pinPickerIndex > 0 { pinPickerIndex -= 1 }
            else { pinPickerIndex = total - 1 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashPinPickerDown)) { _ in
            guard showPinPicker else { return }
            let total = pinPickerTotal
            if pinPickerIndex < total - 1 { pinPickerIndex += 1 }
            else { pinPickerIndex = 0 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashPinPickerSelect)) { _ in
            guard showPinPicker else { return }
            executePinPickerSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashPinPickerCancel)) { _ in
            showPinPicker = false
            NotificationCenter.default.post(name: .stashPinPickerStateChanged, object: nil, userInfo: ["visible": false])
        }
        .onReceive(NotificationCenter.default.publisher(for: .stashPinPickerDigit)) { notification in
            guard showPinPicker, let idx = notification.userInfo?["index"] as? Int else { return }
            pinPickerIndex = idx
            executePinPickerSelection()
        }
        .onAppear {
            let prefs = PreferencesStore.shared
            cardSize = prefs.density.cardWidth
            blurLevel = prefs.blurLevel
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("cardDensityDidChange"))) { _ in
            cardSize = PreferencesStore.shared.density.cardWidth
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("blurAmountDidChange"))) { _ in
            blurLevel = PreferencesStore.shared.blurLevel
        }
    }

    // MARK: - Header (CSS .g-header: toolbar + search + pills in one row)

    private var header: some View {
        HStack(spacing: 10) {
            // Toolbar group: left button → icon-only sidebar; right button → labels mode
            HStack(spacing: 2) {
                toolbarButton("sidebar.left", isActive: !sidebarShowsLabels) {
                    sidebarShowsLabels = false
                }
                toolbarButton("square.grid.2x2", isActive: sidebarShowsLabels) {
                    sidebarShowsLabels = true
                }
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

    private func pinColor(for clip: Clip) -> Color? {
        guard clip.isPinned, let pid = clip.pinboardId else { return nil }
        guard let board = store.pinboards.first(where: { $0.id == pid }) else { return nil }
        return Color(hex: board.accent)
    }

    private var pinPickerTotal: Int {
        let boards = store.sortedPinboards.count
        let hasUnpin = store.clip(at: store.selectedIndex)?.isPinned == true
        return boards + 1 + (hasUnpin ? 1 : 0)  // +1 for Create Pinboard
    }

    private func executePinPickerSelection() {
        let boards = store.sortedPinboards
        guard let clip = store.clip(at: store.selectedIndex) else {
            showPinPicker = false
            NotificationCenter.default.post(name: .stashPinPickerStateChanged, object: nil, userInfo: ["visible": false])
            return
        }
        if pinPickerIndex < boards.count {
            store.pinToPinboard(clip, pinboardId: boards[pinPickerIndex].id)
        } else if pinPickerIndex == boards.count {
            store.createPinboardAndPin(clip: clip)
        } else if clip.isPinned {
            store.unpin(clip)
        }
        showPinPicker = false
        NotificationCenter.default.post(name: .stashPinPickerStateChanged, object: nil, userInfo: ["visible": false])
    }

    private func toolbarButton(_ name: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(isActive ? 0.95 : 0.62))
                .frame(width: 28, height: 28)
                .background(isActive ? Color.white.opacity(0.14) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(Array(store.displayClips.enumerated()), id: \.element.id) { idx, clip in
                            CardView(
                                clip: clip,
                                isSelected: idx == store.selectedIndex,
                                index: idx,
                                searchQuery: store.searchText,
                                cardSize: cardSize,
                                pinColor: pinColor(for: clip)
                            )
                            .id(clip.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    store.selectedIndex = idx
                                }
                            }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    DispatchQueue.main.async {
                                        store.selectedIndex = idx
                                    }
                                    onPaste()
                                }
                            )
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
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                }
                .onChange(of: store.selectedIndex) { newIndex in
                    // Auto-scroll only for keyboard navigation, not clicks
                }
                .onReceive(NotificationCenter.default.publisher(for: .stashKeyboardScroll)) { _ in
                    let idx = store.selectedIndex
                    guard idx >= 0, idx < store.displayClips.count else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(store.displayClips[idx].id, anchor: .leading)
                    }
                }
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
        ZStack {
            Color.white.opacity(0.03)
            VStack(spacing: 10) {
                Text(store.searchText.isEmpty ? "\u{1F4CB}" : "\u{1F50D}")
                    .font(.system(size: 36))
                    .opacity(0.6)
                Text(store.searchText.isEmpty ? "No clips yet" : "No matches found")
                    .font(.system(size: 13.5))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: .infinity)
    }

    // MARK: - Edit Overlay

    @State private var editOverlayText: String = ""

    private func editOverlay(clip: Clip) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { editingClip = nil }

            VStack(spacing: 16) {
                Text("Edit Clip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                TextEditor(text: $editOverlayText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minWidth: 360, minHeight: 150)

                HStack {
                    Button("Cancel") { editingClip = nil }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button("Save") {
                        store.updateClipText(clip, newText: editOverlayText)
                        editingClip = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
            .frame(width: 420)
            .background(Color(red: 15/255, green: 23/255, blue: 42/255))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .onAppear {
            editOverlayText = clip.textContent ?? ""
        }
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

    // MARK: - Pin Picker (⌘P popup)

    private var pinPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showPinPicker = false }

            VStack(spacing: 0) {
                Text("Pin to Pinboard")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .overlay(
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5),
                        alignment: .bottom
                    )

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(store.sortedPinboards.enumerated()), id: \.element.id) { idx, board in
                                pinPickerRow(board: board, index: idx)
                                    .id(board.id)
                            }
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.vertical, 4)
                            pinPickerCreateRow(index: store.sortedPinboards.count)
                            if let clip = store.clip(at: store.selectedIndex), clip.isPinned {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.vertical, 4)
                                pinPickerUnpinRow(index: store.sortedPinboards.count + 1)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .frame(maxHeight: 260)
                    .onChange(of: pinPickerIndex) { newIndex in
                        let boards = store.sortedPinboards
                        let total = boards.count + (store.clip(at: store.selectedIndex)?.isPinned == true ? 1 : 0)
                        guard newIndex >= 0, newIndex < total else { return }
                        if newIndex < boards.count {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(boards[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    footerKbd("↑↓", "Navigate")
                    footerKbd("↵", "Pin")
                    footerKbd("Esc", "Cancel")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5),
                    alignment: .top
                )
            }
            .frame(width: 260)
            .background(Color(red: 28/255, green: 28/255, blue: 32/255, opacity: 0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .onReceive(NotificationCenter.default.publisher(for: .stashShowPinPicker)) { _ in }
        }
        .onAppear {
            // Focus the panel so key events work
            if let window = NSApp.keyWindow {
                window.makeFirstResponder(nil)
            }
        }
    }

    private func pinPickerRow(board: Pinboard, index: Int) -> some View {
        let isSelected = pinPickerIndex == index
        let boardColor = Color(hex: board.accent) ?? accentColor
        let clip = store.clip(at: store.selectedIndex)
        let isCurrent = clip?.pinboardId == board.id && clip?.isPinned == true

        return Button(action: {
            if let clip = clip {
                store.pinToPinboard(clip, pinboardId: board.id)
            }
            showPinPicker = false
        }) {
            HStack(spacing: 10) {
                Circle()
                    .fill(boardColor)
                    .frame(width: 12, height: 12)
                Text(board.name)
                    .font(.system(size: 12.5))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.75))
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(boardColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func pinPickerCreateRow(index: Int) -> some View {
        let isSelected = pinPickerIndex == index
        return Button(action: {
            if let clip = store.clip(at: store.selectedIndex) {
                store.createPinboardAndPin(clip: clip)
            }
            showPinPicker = false
            NotificationCenter.default.post(name: .stashPinPickerStateChanged, object: nil, userInfo: ["visible": false])
        }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                    .frame(width: 12)
                Text("Create Pinboard")
                    .font(.system(size: 12.5))
                    .foregroundColor(isSelected ? .white : accentColor.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func pinPickerUnpinRow(index: Int) -> some View {
        let isSelected = pinPickerIndex == index
        return Button(action: {
            if let clip = store.clip(at: store.selectedIndex) {
                store.unpin(clip)
            }
            showPinPicker = false
        }) {
            HStack(spacing: 10) {
                Image(systemName: "pin.slash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 12)
                Text("Unpin")
                    .font(.system(size: 12.5))
                    .foregroundColor(isSelected ? .white : .red.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .padding(.vertical, 11)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: - Panel Appearance (Legacy gradient + Liquid Glass)

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

private struct PanelAppearanceModifier: ViewModifier {
    let blurLevel: Int

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
        } else {
            content
                .background(
                    ZStack {
                        gradientBackground
                        Color(red: 28/255, green: 28/255, blue: 32/255).opacity(0.35)
                            .background(materialForBlurLevel)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        .mask(
                            Rectangle()
                                .frame(height: 1)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                )
        }
    }

    private var materialForBlurLevel: Material {
        switch blurLevel {
        case 0: return .thinMaterial
        case 2: return .thickMaterial
        default: return .ultraThinMaterial
        }
    }

    private var gradientBackground: some View {
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
        .allowsHitTesting(false)
    }
}
