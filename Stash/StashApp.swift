import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var store: ClipboardStore!
    var panel: GalleryPanel!
    var clipboardWatcher: ClipboardWatcher!
    var globalHotKey: GlobalHotKey?
    var preferencesWindow: PreferencesWindow?
    let prefs = PreferencesStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusBarIcon()
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
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
        panel.onPlainPaste = { [weak self] in
            self?.pastePlainSelected()
        }

        // Clipboard watcher
        clipboardWatcher = ClipboardWatcher()
        clipboardWatcher.onCopy = { [weak self] in
            DispatchQueue.main.async {
                self?.store.processClip()
                self?.enforceHistoryLimit()
            }
        }
        clipboardWatcher.start()

        // Global hotkey
        globalHotKey = GlobalHotKey(keyboardShortcut: .commandShiftV) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }

        // Preferences observer for menu bar icon visibility
        prefs.$showMenuBarIcon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.statusItem.isVisible = show
            }
            .store(in: &cancellables)
    }

    private var cancellables: [AnyCancellable] = []

    private func updateStatusBarIcon() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Stash")
        }
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
        }
        preferencesWindow?.showWindow()
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

    private func pastePlainSelected() {
        guard let clip = store.clip(at: store.selectedIndex) else { return }
        clip.writeToPasteboard(plainTextOnly: true)
        panel.orderOut(nil)
        PasteSimulator.simulatePaste()
    }

    private func enforceHistoryLimit() {
        let limit = prefs.historyLimit
        guard limit > 0, store.clips.count > limit else { return }

        // Separate pinned and unpinned
        let pinned = store.clips.filter { $0.isPinned }
        var unpinned = store.clips.filter { !$0.isPinned }

        let excess = store.clips.count - limit
        guard excess > 0 else { return }

        // Remove oldest unpinned first
        let toRemove = min(excess, unpinned.count)
        let removedItems = Array(unpinned.suffix(toRemove))
        for item in removedItems {
            if let path = item.imagePath {
                BlobStore.shared.delete(path)
            }
        }

        var remaining = store.clips.filter { clip in
            !removedItems.contains(where: { $0.id == clip.id })
        }
        // Keep newest first order
        remaining.sort { $0.createdAt > $1.createdAt }
        store.clips = remaining
    }
}
