import SwiftUI
import AppKit

final class GalleryPanel: NSPanel {
    private let store: ClipboardStore
    private var galleryView: GalleryView?
    var onPaste: (() -> Void)?
    var onClose: (() -> Void)?
    var onQuickPaste: ((Int) -> Void)?
    var onPlainPaste: (() -> Void)?

    init(store: ClipboardStore) {
        self.store = store

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 440),
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
        self.hasShadow = true
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
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

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

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch event.keyCode {
        case 123: // left arrow
            store.selectPrevious()
        case 124: // right arrow
            store.selectNext()
        case 36: // return
            if modifiers == .shift {
                handlePlainPaste()
            } else {
                handlePaste()
            }
        case 53: // escape
            handleClose()
        case 49: // space
            toggleQuickLook()
        default:
            // ⌘1-9 quick paste
            if modifiers == .command,
               let char = event.charactersIgnoringModifiers,
               let digit = Int(char), (1...9).contains(digit) {
                onQuickPaste?(digit - 1)
            }
            // ⌘F focus search
            else if modifiers == .command, event.charactersIgnoringModifiers == "f" {
                // Search field is already focused via TextField
                super.keyDown(with: event)
            }
            // ⇧⌘V plain paste
            else if modifiers == [.command, .shift], event.keyCode == 9 { // V key
                handlePlainPaste()
            }
            else {
                super.keyDown(with: event)
            }
        }
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

    private func toggleQuickLook() {
        // Toggle Quick Look via the galleryView's isQuickLooking state
        // This is handled through the SwiftUI view's @State
        NotificationCenter.default.post(name: .stashToggleQuickLook, object: nil)
    }
}

extension Notification.Name {
    static let stashToggleQuickLook = Notification.Name("stashToggleQuickLook")
}
