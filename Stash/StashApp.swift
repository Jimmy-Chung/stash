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
            Button("Preferences...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quit Stash") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            PreferencesRootView()
        }
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

        let hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        hotKey.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        globalHotKey = hotKey

        NotificationCenter.default.addObserver(
            forName: .stashOpenPreferences,
            object: nil, queue: .main
        ) { _ in
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
