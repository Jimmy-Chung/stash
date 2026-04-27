import SwiftUI
import AppKit

final class GalleryPanel: NSPanel {
    private let store: ClipboardStore
    var onPaste: (() -> Void)?
    var onClose: (() -> Void)?
    var onQuickPaste: ((Int) -> Void)?

    init(store: ClipboardStore) {
        self.store = store

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 380),
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

        let galleryView = GalleryView(
            store: store,
            onPaste: { [weak self] in self?.handlePaste() },
            onClose: { [weak self] in self?.handleClose() }
        )

        let hostingView = NSHostingView(rootView: galleryView)
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
        let panelHeight: CGFloat = 380
        let panelX = visibleFrame.minX + 16
        let panelY = visibleFrame.minY

        setFrame(NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight), display: true)
        makeKeyAndOrderFront(nil)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: // left arrow
            store.selectPrevious()
        case 124: // right arrow
            store.selectNext()
        case 36: // return
            handlePaste()
        case 53: // escape
            handleClose()
        default:
            if event.modifierFlags.contains(.command),
               let char = event.charactersIgnoringModifiers,
               let digit = Int(char), (1...9).contains(digit) {
                onQuickPaste?(digit - 1)
            } else {
                super.keyDown(with: event)
            }
        }
    }

    private func handlePaste() {
        onPaste?()
    }

    private func handleClose() {
        orderOut(nil)
        onClose?()
    }
}
