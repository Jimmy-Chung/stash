import SwiftUI
import AppKit

final class GalleryPanel: NSPanel {
    private let store: ClipboardStore
    private var galleryView: GalleryView?
    var onPaste: (() -> Void)?
    var onClose: (() -> Void)?
    var onPlainPaste: (() -> Void)?

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
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    private var isSpaceDown = false

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags
        let keyCode = event.keyCode
        let chars = event.charactersIgnoringModifiers

        // Command combinations
        if mods.contains(.command) {
            // ⌘1-9: Quick paste
            if let char = chars, let digit = Int(char), (1...9).contains(digit) {
                if let clip = store.clip(at: digit - 1) {
                    clip.writeToPasteboard()
                    handleClose()
                    PasteSimulator.simulatePaste()
                }
                return
            }
            switch chars {
            case "p":
                NotificationCenter.default.post(name: .stashTogglePin, object: nil)
                return
            case "e":
                NotificationCenter.default.post(name: .stashEditClip, object: nil)
                return
            case "f":
                focusSearchField()
                return
            case "[":
                store.switchToPreviousPinboard()
                return
            case "]":
                store.switchToNextPinboard()
                return
            default: break
            }
        }

        // Shift+Return: plain paste
        if keyCode == 36 && mods.contains(.shift) && !mods.contains(.command) {
            handlePlainPaste()
            return
        }

        // Return: paste
        if keyCode == 36 && !mods.contains(.command) {
            handlePaste()
            return
        }

        switch keyCode {
        case 123: // Left
            store.selectPrevious()
        case 124: // Right
            store.selectNext()
        case 53: // Escape
            handleClose()
        case 49: // Space
            if !isSpaceDown {
                isSpaceDown = true
                NotificationCenter.default.post(name: .stashToggleQuickLook, object: nil)
            }
        case 51: // Delete
            if let clip = store.clip(at: store.selectedIndex) {
                if clip.isPinned {
                    NotificationCenter.default.post(name: .stashDeleteClip, object: clip)
                } else {
                    store.deleteClip(clip)
                }
            }
        default:
            super.keyDown(with: event)
        }
    }

    override func keyUp(with event: NSEvent) {
        if event.keyCode == 49 && isSpaceDown {
            isSpaceDown = false
            NotificationCenter.default.post(name: .stashToggleQuickLook, object: nil)
        }
        super.keyUp(with: event)
    }

    override func resignKey() {
        super.resignKey()
        if PreferencesStore.shared.autoHideOnFocusLoss {
            orderOut(nil)
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
        makeKeyAndOrderFront(nil)
    }

    private func focusSearchField() {
        guard let contentView = contentView else { return }
        let textField = findTextField(in: contentView)
        if let field = textField {
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
