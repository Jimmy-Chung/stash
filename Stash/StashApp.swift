import SwiftUI
import AppKit
import HotKey
import SwiftData

@main
struct StashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var prefs = PreferencesStore.shared

    var body: some Scene {
        MenuBarExtra("Stash", systemImage: "doc.on.clipboard", isInserted: Binding(
            get: { prefs.showMenuBarIcon },
            set: { prefs.showMenuBarIcon = $0 }
        )) {
            MenuBarContent()
        }

        Window("Stash Preferences", id: "preferences") {
            PreferencesRootView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 540)
    }
}

struct MenuBarContent: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Button("Preferences...") {
            openWindow(id: "preferences")
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit Stash") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var store: ClipboardStore!
    var panel: GalleryPanel!
    var clipboardWatcher: ClipboardWatcher!
    var globalHotKey: HotKey?
    let prefs = PreferencesStore.shared
    var modelContainer: ModelContainer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            modelContainer = try ModelContainer(for: Clip.self, Pinboard.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let context = modelContainer.mainContext
        store = ClipboardStore(modelContext: context)
        panel = GalleryPanel(store: store)

        panel.onPaste = { [weak self] in
            self?.pasteSelected()
        }
        panel.onPlainPaste = { [weak self] in
            self?.pastePlainSelected()
        }

        clipboardWatcher = ClipboardWatcher()
        clipboardWatcher.onCopy = { [weak self] in
            DispatchQueue.main.async {
                self?.store.processClip()
                self?.enforceHistoryLimit()
            }
        }
        clipboardWatcher.start()

        setupGlobalHotKey()

        NotificationCenter.default.addObserver(
            forName: .stashHotkeyChanged,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.setupGlobalHotKey()
        }

        NotificationCenter.default.addObserver(
            forName: .stashOpenPreferences,
            object: nil, queue: .main
        ) { _ in
            if let window = NSApp.windows.first(where: { $0.title == "Stash Preferences" }) {
                window.makeKeyAndOrderFront(nil)
            } else {
                NSApp.sendAction(Selector(("openWindow:")), to: nil, from: nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }

        // 90-day data retention cleanup
        store.cleanupExpiredClips()
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.store.cleanupExpiredClips()
        }

        // Accessibility startup guide (async to avoid blocking launch)
        DispatchQueue.main.async {
            if !AccessibilityChecker.isTrusted {
                let alert = NSAlert()
                alert.messageText = "Stash Needs Accessibility Access"
                alert.informativeText = "Stash requires Accessibility permission to simulate paste (⌘V).\n\nClick OK to open System Settings, then enable Stash under Privacy > Accessibility."
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")
                alert.alertStyle = .warning
                if alert.runModal() == .alertFirstButtonReturn {
                    AccessibilityChecker.openSystemSettings()
                }
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

    private func pastePlainSelected() {
        guard let clip = store.clip(at: store.selectedIndex) else { return }
        clip.writeToPasteboard(plainTextOnly: true)
        panel.orderOut(nil)
        PasteSimulator.simulatePaste()
    }

    private func setupGlobalHotKey() {
        let mods = NSEvent.ModifierFlags(rawValue: UInt(prefs.globalHotKeyModifiers))

        // Default fallback: ⌘⇧V
        let key: HotKey
        if prefs.globalHotKeyCode == 0 && prefs.globalHotKeyModifiers == 0 {
            key = HotKey(key: .v, modifiers: [.command, .shift])
        } else if let hk = Key(carbonKeyCode: prefs.globalHotKeyCode) {
            key = HotKey(key: hk, modifiers: mods)
        } else {
            key = HotKey(key: .v, modifiers: [.command, .shift])
        }
        key.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        globalHotKey = key
    }

    private func enforceHistoryLimit() {
        let limit = prefs.historyLimit
        guard limit > 0, store.clips.count > limit else { return }

        let unpinned = store.clips.filter { !$0.isPinned }

        let excess = store.clips.count - limit
        guard excess > 0 else { return }

        let toRemove = min(excess, unpinned.count)
        let removedItems = Array(unpinned.suffix(toRemove))
        store.deleteClips(removedItems)
    }
}
