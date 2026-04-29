import SwiftUI
import AppKit

final class GalleryPanel: NSPanel {
    private let store: ClipboardStore
    private var galleryView: GalleryView?
    var onPaste: (() -> Void)?
    var onClose: (() -> Void)?
    var onPlainPaste: (() -> Void)?

    private var keyMonitor: Any?
    private var isSpaceDown = false
    private var autoHideOnFocusLoss: Bool = PreferencesStore.shared.autoHideOnFocusLoss

    private var autoHideObserver: NSObjectProtocol?

    init(store: ClipboardStore) {
        self.store = store

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 440),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let gallery = GalleryView(
            store: store,
            onPaste: { [weak self] in self?.handlePaste() },
            onClose: { [weak self] in self?.handleClose() },
            onPlainPaste: { [weak self] in self?.handlePlainPaste() }
        )
        self.galleryView = gallery

        let hostingView = NSHostingView(rootView: gallery)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        self.contentView?.addSubview(hostingView)

        NotificationCenter.default.addObserver(
            forName: .stashFocusSearch,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.focusSearchField()
        }

        setupPreferenceObservers()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func resignKey() {
        super.resignKey()
        if autoHideOnFocusLoss {
            removeKeyMonitor()
            orderOut(nil)
        }
    }

    private func setupPreferenceObservers() {
        autoHideObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("autoHideOnFocusLossDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.autoHideOnFocusLoss = PreferencesStore.shared.autoHideOnFocusLoss
        }
    }

    func show() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let panelWidth = visibleFrame.width - 32
        let panelHeight: CGFloat = 440
        let panelX = visibleFrame.minX + 16
        let panelY = visibleFrame.minY

        setFrame(NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight), display: true)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        // Don't auto-focus the search field on open — keyboard nav (←/→) should
        // work immediately. User presses ⌘F or starts typing to enter search.
        makeFirstResponder(nil)
        installKeyMonitor()
    }

    // MARK: - Key Monitor

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.isVisible else { return event }

            if event.type == .keyDown, self.handleKey(event) {
                return nil
            }
            if event.type == .keyUp, self.handleKeyUp(event) {
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        isSpaceDown = false
    }

    private var isEditingTextField: Bool {
        guard let responder = firstResponder else { return false }
        if responder is NSTextView { return true }
        if let tf = responder as? NSTextField, tf.isEditable { return true }
        return false
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags
        let keyCode = event.keyCode
        let chars = event.charactersIgnoringModifiers
        let editing = isEditingTextField

        if mods.contains(.command) {
            if let char = chars, let digit = Int(char), (1...9).contains(digit) {
                if store.clip(at: digit - 1) != nil {
                    store.selectedIndex = digit - 1
                    handlePaste()
                }
                return true
            }
            switch chars {
            case "p":
                NotificationCenter.default.post(name: .stashTogglePin, object: nil)
                return true
            case "e":
                NotificationCenter.default.post(name: .stashEditClip, object: nil)
                return true
            case "f":
                focusSearchField()
                return true
            case "[":
                store.switchToPreviousPinboard()
                return true
            case "]":
                store.switchToNextPinboard()
                return true
            default: return false
            }
        }

        // Esc: blur the search field if it's focused, otherwise close the panel
        if keyCode == 53 {
            if editing {
                makeFirstResponder(nil)
                return true
            }
            handleClose()
            return true
        }

        // ←/→ always navigate cards, even while the search field is focused.
        // Editing the query with ←/→ inside the field is sacrificed for discoverability.
        switch keyCode {
        case 123: store.selectPrevious(); return true
        case 124: store.selectNext(); return true
        default: break
        }

        // When typing in search/rename, let everything else through (Space, Backspace, Enter)
        if editing { return false }

        if keyCode == 36 && mods.contains(.shift) {
            handlePlainPaste()
            return true
        }
        if keyCode == 36 {
            handlePaste()
            return true
        }

        switch keyCode {
        case 49:
            if !isSpaceDown {
                isSpaceDown = true
                NotificationCenter.default.post(name: .stashToggleQuickLook, object: nil)
            }
            return true
        case 51:
            if let clip = store.clip(at: store.selectedIndex) {
                if clip.isPinned {
                    NotificationCenter.default.post(name: .stashDeleteClip, object: clip)
                } else {
                    store.deleteClip(clip)
                }
            }
            return true
        default: break
        }

        // Type-ahead: a printable character with no Command modifier focuses the
        // search field and lets the same event flow through to insert the char.
        if let s = chars, isPrintableForSearch(s) {
            focusSearchField()
            return false
        }

        return false
    }

    private func isPrintableForSearch(_ chars: String) -> Bool {
        guard let scalar = chars.unicodeScalars.first else { return false }
        let v = scalar.value
        // Reject control chars (incl. Tab/Return/Backspace) and DEL.
        if v < 0x20 || v == 0x7F { return false }
        // Reject Cocoa function-key range (arrows, F1-F12, Home/End, etc.).
        if v >= 0xF700 && v <= 0xF8FF { return false }
        return true
    }

    private func handleKeyUp(_ event: NSEvent) -> Bool {
        if event.keyCode == 49 && isSpaceDown {
            isSpaceDown = false
            NotificationCenter.default.post(name: .stashToggleQuickLook, object: nil)
            return true
        }
        return false
    }

    // MARK: - Helpers

    private func focusSearchField() {
        guard let contentView = contentView else { return }
        if let field = findTextField(in: contentView) {
            makeFirstResponder(field)
        }
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        for child in view.subviews {
            if let tf = child as? NSTextField, tf.isEditable {
                return tf
            }
            if let found = findTextField(in: child) {
                return found
            }
        }
        return nil
    }

    private func handlePaste() {
        onPaste?()
    }

    private func handlePlainPaste() {
        onPlainPaste?()
    }

    private func handleClose() {
        removeKeyMonitor()
        orderOut(nil)
        onClose?()
    }
}

extension Notification.Name {
    static let stashToggleQuickLook = Notification.Name("stashToggleQuickLook")
    static let stashDeleteClip = Notification.Name("stashDeleteClip")
    static let stashTogglePin = Notification.Name("stashTogglePin")
    static let stashEditClip = Notification.Name("stashEditClip")
    static let stashOpenPreferences = Notification.Name("stashOpenPreferences")
    static let stashFocusSearch = Notification.Name("stashFocusSearch")
    static let stashHotkeyChanged = Notification.Name("stashHotkeyChanged")
}
