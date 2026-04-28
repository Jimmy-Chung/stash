import SwiftUI
import AppKit
import HotKey
import SwiftData

@main
struct StashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var prefs = PreferencesStore.shared

    var body: some Scene {
        MenuBarExtra("Stash", image: "menu-icon", isInserted: Binding(
            get: { prefs.showMenuBarIcon },
            set: { prefs.showMenuBarIcon = $0 }
        )) {
            MenuBarContent()
        }
    }
}

struct MenuBarContent: View {
    var body: some View {
        Button("Preferences...") {
            (NSApp.delegate as? AppDelegate)?.showPreferences()
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
    var preferencesWindow: NSWindow?
    var clipboardWatcher: ClipboardWatcher!
    var globalHotKey: HotKey?
    let prefs = PreferencesStore.shared
    var modelContainer: ModelContainer!
    var previousApp: NSRunningApplication?

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

        registerGlobalHotKey()

        NotificationCenter.default.addObserver(
            forName: .stashHotkeyChanged,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.registerGlobalHotKey()
        }

        NotificationCenter.default.addObserver(
            forName: .stashOpenPreferences,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.showPreferences()
        }

        // 90-day data retention cleanup
        store.cleanupExpiredClips()
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.store.cleanupExpiredClips()
        }

        // Accessibility startup guide (async to avoid blocking launch)
        // Skip in test environment to avoid blocking on modal alert
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTesting {
            DispatchQueue.main.async {
                if !AccessibilityChecker.isTrusted {
                    let alert = NSAlert()
                    alert.messageText = "Stash Needs Accessibility Access"
                    alert.informativeText = "Stash requires Accessibility permission to simulate paste (\u{2318}V).\n\nClick OK to open System Settings, then enable Stash under Privacy > Accessibility."
                    alert.addButton(withTitle: "Open System Settings")
                    alert.addButton(withTitle: "Later")
                    alert.alertStyle = .warning
                    if alert.runModal() == .alertFirstButtonReturn {
                        AccessibilityChecker.openSystemSettings()
                    }
                }
            }
        }
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            previousApp = NSWorkspace.shared.frontmostApplication
            panel.show()
        }
    }

    @objc func showPreferences() {
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: PreferencesRootView())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentViewController = hostingController

        self.preferencesWindow = window
        panel.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func pasteSelected() {
        guard let clip = store.clip(at: store.selectedIndex) else { return }
        clip.writeToPasteboard()
        restorePreviousAppAndPaste()
    }

    private func pastePlainSelected() {
        guard let clip = store.clip(at: store.selectedIndex) else { return }
        clip.writeToPasteboard(plainTextOnly: true)
        restorePreviousAppAndPaste()
    }

    private func restorePreviousAppAndPaste() {
        let app = previousApp
        panel.orderOut(nil)
        if let app = app {
            app.activate(options: .activateIgnoringOtherApps)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            PasteSimulator.simulatePaste()
        }
    }

    private func registerGlobalHotKey() {
        let hotKey: HotKey
        if prefs.globalHotKeyModifiers == 0 {
            hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        } else {
            let mods = NSEvent.ModifierFlags(rawValue: UInt(prefs.globalHotKeyModifiers))
            if let hk = Key(carbonKeyCode: prefs.globalHotKeyCode) {
                hotKey = HotKey(key: hk, modifiers: mods)
            } else {
                hotKey = HotKey(key: .v, modifiers: [.command, .shift])
            }
        }
        hotKey.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        globalHotKey = hotKey
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
