import SwiftUI
import AppKit

final class PreferencesWindow: NSWindowController {
    convenience init() {
        let view = PreferencesTabView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 520, height: 420)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Stash Preferences"
        window.contentView = hosting
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
    }

    func showWindow() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralTabView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(0)

            ShortcutsTabView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(1)

            AppearanceTabView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
                .tag(2)
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
}

// MARK: - General Tab

struct GeneralTabView: View {
    @ObservedObject var prefs = PreferencesStore.shared

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $prefs.launchAtLogin)

            Toggle("Show Menu Bar Icon", isOn: $prefs.showMenuBarIcon)

            HStack {
                Text("History Limit")
                Picker("", selection: $prefs.historyLimit) {
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("Unlimited").tag(0)
                }
                .frame(width: 120)
            }

            Toggle("Sound Effects", isOn: $prefs.soundEnabled)

            Toggle("Auto-hide on Focus Loss", isOn: $prefs.autoHideOnFocusLoss)
        }
    }
}

// MARK: - Shortcuts Tab

struct ShortcutsTabView: View {
    @ObservedObject var prefs = PreferencesStore.shared
    @State private var isRecording = false
    @State private var recordedKey: String = ""

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Global Hotkey")
                .font(.system(size: 13, weight: .semibold))

            HStack {
                Text("Show/Hide Panel:")
                    .frame(width: 130, alignment: .leading)

                Button(action: { isRecording = true }) {
                    Text(isRecording ? "Press new shortcut..." : currentHotKeyLabel)
                        .frame(width: 180)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .background(isRecording ? accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(isRecording ? accentColor : Color.gray.opacity(0.3)))
            }

            Divider()

            Text("Internal Shortcuts (read-only)")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Group {
                    shortcutRow("← →", "Navigate between clips")
                    shortcutRow("Enter", "Paste selected clip")
                    shortcutRow("⇧ Enter", "Paste as plain text")
                    shortcutRow("Esc", "Close panel")
                    shortcutRow("Space", "Quick Look preview")
                    shortcutRow("⌘1-9", "Quick paste by index")
                }
                Group {
                    shortcutRow("⌘P", "Pin / Unpin selected")
                    shortcutRow("⌘E", "Edit selected clip")
                    shortcutRow("⌘[ ⌘]", "Switch Pinboard")
                    shortcutRow("⌫", "Delete selected clip")
                    shortcutRow("⌘F", "Focus search box")
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var currentHotKeyLabel: String {
        "⌘⇧V"
    }

    private func shortcutRow(_ keys: String, _ desc: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.secondary)
            Text(desc)
                .font(.system(size: 12))
        }
    }
}

// MARK: - Appearance Tab

struct AppearanceTabView: View {
    @ObservedObject var prefs = PreferencesStore.shared

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        Form {
            HStack {
                Text("Theme")
                Picker("", selection: $prefs.appearanceMode) {
                    Text("Follow System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .frame(width: 140)
            }

            VStack(alignment: .leading) {
                Text("Glass Blur Amount")
                HStack {
                    Slider(value: $prefs.blurAmount, in: 10...80, step: 5)
                    Text("\(Int(prefs.blurAmount))%")
                        .frame(width: 40)
                        .font(.system(size: 12, design: .monospaced))
                }
            }

            HStack {
                Text("Card Density")
                Picker("", selection: $prefs.cardDensity) {
                    Text("Compact").tag(0)
                    Text("Default").tag(1)
                    Text("Cozy").tag(2)
                }
                .frame(width: 120)
            }
        }
    }
}
