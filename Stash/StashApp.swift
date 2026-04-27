import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var store: ClipboardStore!
    var panel: GalleryPanel!
    var clipboardWatcher: ClipboardWatcher!
    var globalHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Stash")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Stash", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        // Store + Panel
        store = ClipboardStore()
        panel = GalleryPanel(store: store)

        panel.onPaste = { [weak self] in
            self?.pasteSelected()
        }
        panel.onQuickPaste = { [weak self] index in
            self?.quickPaste(at: index)
        }

        // Clipboard watcher
        clipboardWatcher = ClipboardWatcher()
        clipboardWatcher.onCopy = { [weak self] in
            DispatchQueue.main.async {
                self?.store.processClip()
            }
        }
        clipboardWatcher.start()

        // Global hotkey
        globalHotKey = GlobalHotKey(keyboardShortcut: .commandShiftV) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.show()
        }
    }

    private func pasteSelected() {
        guard let clip = store.clip(at: store.selectedIndex) else { return }
        clip.writeToPasteboard()
        panel.orderOut(nil)
        PasteSimulator.simulatePaste()
    }

    private func quickPaste(at index: Int) {
        guard let clip = store.clip(at: index) else { return }
        clip.writeToPasteboard()
        panel.orderOut(nil)
        PasteSimulator.simulatePaste()
    }
}
