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
}
