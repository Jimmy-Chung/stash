import SwiftUI
import AppKit

// MARK: - Root View

struct PreferencesRootView: View {
    @State private var selectedTab = 0

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        VStack(spacing: 0) {
            // Titlebar spacer (traffic lights area)
            HStack {
                Spacer()
            }
            .frame(height: 38)
            .overlay(
                Text("Stash Preferences")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white),
                alignment: .center
            )

            // Tabs
            HStack(spacing: 4) {
                tabButton(index: 0, icon: "gear", label: "General")
                tabButton(index: 1, icon: "keyboard", label: "Shortcuts")
                tabButton(index: 2, icon: "paintbrush", label: "Appearance")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5),
                alignment: .bottom
            )

            // Body
            Group {
                switch selectedTab {
                case 0: GeneralTabContent()
                case 1: ShortcutsTabContent()
                case 2: AppearanceTabContent()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 720, height: 540)
        .background(
            ZStack {
                Color(red: 40/255, green: 40/255, blue: 44/255).opacity(0.82)
                    .background(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.6), radius: 40, y: 20)
    }

    private func tabButton(index: Int, icon: String, label: String) -> some View {
        let isActive = selectedTab == index
        return Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, Color(red: 231/255, green: 111/255, blue: 81/255)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 26, height: 26)
                        .shadow(
                            color: isActive ? accentColor.opacity(0.35) : .clear,
                            radius: 4, y: 2
                        )
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.78))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color.white.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab

struct GeneralTabContent: View {
    @ObservedObject var prefs = PreferencesStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                prefsRow("Launch at Login", help: "Start Stash automatically when you log in") {
                    MacOSToggle(isOn: $prefs.launchAtLogin)
                }
                prefsRow("Show Menu Bar Icon", help: "Display the clipboard icon in the menu bar") {
                    MacOSToggle(isOn: $prefs.showMenuBarIcon)
                }
                prefsRow("History Limit", help: "Maximum number of clips to keep") {
                    HStack(spacing: 8) {
                        prefsPicker(selection: $prefs.historyLimit) {
                            Text("100").tag(100)
                            Text("500").tag(500)
                            Text("1000").tag(1000)
                            Text("Unlimited").tag(0)
                        }
                    }
                }
                prefsRow("Sound Effects", help: "Play sounds on copy and paste") {
                    MacOSToggle(isOn: $prefs.soundEnabled)
                }
                prefsRow("Auto-hide on Focus Loss", help: "Close the panel when clicking outside") {
                    MacOSToggle(isOn: $prefs.autoHideOnFocusLoss)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Shortcuts Tab

struct ShortcutsTabContent: View {
    @ObservedObject var prefs = PreferencesStore.shared
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Global hotkey recorder
                prefsRow("Global Hotkey", help: "Press the button then type your new shortcut") {
                    HStack(spacing: 8) {
                        Button(action: { toggleRecording() }) {
                            Text(isRecording ? "Press new shortcut..." : shortcutDisplayText)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(isRecording ? .white : .white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(isRecording ? accentColor.opacity(0.18) : Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(
                                            isRecording ? accentColor.opacity(0.5) : Color.white.opacity(0.1),
                                            lineWidth: 0.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().background(Color.white.opacity(0.06)).padding(.vertical, 14)

                // Internal shortcuts table
                Text("Internal Shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                VStack(spacing: 0) {
                    Group {
                        shortcutRow("\u{2190} \u{2192}", "Navigate between clips")
                        shortcutRow("Enter", "Paste selected clip")
                        shortcutRow("\u{21E7} Enter", "Paste as plain text")
                        shortcutRow("Esc", "Close panel")
                        shortcutRow("Space", "Quick Look preview")
                    }
                    Group {
                        shortcutRow("\u{2318}1-9", "Quick paste by index")
                        shortcutRow("\u{2318}P", "Pin / Unpin selected")
                        shortcutRow("\u{2318}E", "Edit selected clip")
                        shortcutRow("\u{2318}[ \u{2318}]", "Switch Pinboard")
                        shortcutRow("\u{232B}", "Delete selected clip")
                        shortcutRow("\u{2318}F", "Focus search box")
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    private func shortcutRow(_ keys: String, _ desc: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            Spacer()
            Text(desc)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.78))
        }
        .padding(.vertical, 11)
        .overlay(
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var shortcutDisplayText: String {
        if prefs.globalHotKeyCode == 0 && prefs.globalHotKeyModifiers == 0 {
            return "\u{2318}\u{21E7}V"
        }
        var parts: [String] = []
        let mods = NSEvent.ModifierFlags(rawValue: UInt(prefs.globalHotKeyModifiers))
        if mods.contains(.command) { parts.append("\u{2318}") }
        if mods.contains(.option) { parts.append("\u{2325}") }
        if mods.contains(.control) { parts.append("\u{2303}") }
        if mods.contains(.shift) { parts.append("\u{21E7}") }
        if let keyChar = keyChar(for: UInt16(prefs.globalHotKeyCode)) {
            parts.append(keyChar)
        } else {
            parts.append("?")
        }
        return parts.joined()
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !mods.isEmpty else { return event }
            self.prefs.globalHotKeyModifiers = UInt32(mods.rawValue)
            self.prefs.globalHotKeyCode = UInt32(event.keyCode)
            self.stopRecording()
            NotificationCenter.default.post(name: .stashHotkeyChanged, object: nil)
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRecording = false
    }

    private func keyChar(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"; case 1: return "S"; case 2: return "D"; case 3: return "F"
        case 4: return "H"; case 5: return "G"; case 6: return "Z"; case 7: return "X"
        case 8: return "C"; case 9: return "V"; case 10: return "B"; case 11: return "Q"
        case 12: return "W"; case 13: return "E"; case 14: return "R"; case 15: return "Y"
        case 16: return "T"; case 31: return "O"; case 32: return "U"; case 34: return "I"
        case 35: return "P"; case 36: return "Enter"; case 37: return "L"; case 38: return "J"
        case 40: return "K"; case 49: return "Space"; case 51: return "Delete"
        default: return nil
        }
    }
}

// MARK: - Appearance Tab

struct AppearanceTabContent: View {
    @ObservedObject var prefs = PreferencesStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                prefsRow("Theme", help: "Choose light, dark, or follow your system setting") {
                    prefsPicker(selection: $prefs.appearanceMode) {
                        Text("Follow System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }
                prefsRow("Glass Blur Amount", help: "Adjust the blur intensity of the glass panel") {
                    HStack(spacing: 10) {
                        Slider(value: $prefs.blurAmount, in: 10...80, step: 5)
                            .frame(width: 200)
                        Text("\(Int(prefs.blurAmount))%")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40)
                    }
                }
                prefsRow("Card Density", help: "Change the size of clipboard cards") {
                    prefsPicker(selection: $prefs.cardDensity) {
                        Text("Compact").tag(0)
                        Text("Default").tag(1)
                        Text("Cozy").tag(2)
                    }
                }
                prefsRow("Wallpaper Theme", help: "Change the background gradient style") {
                    prefsPicker(selection: $prefs.wallpaperTheme) {
                        Text("Warm").tag(0)
                        Text("Cool").tag(1)
                        Text("Mono").tag(2)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Shared Components

private func prefsRow<Content: View>(_ label: String, help: String, @ViewBuilder control: () -> Content) -> some View {
    HStack(alignment: .top, spacing: 18) {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Text(help)
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
        }
        .frame(width: 200, alignment: .topLeading)

        Spacer()

        control()
    }
    .padding(.vertical, 14)
    .overlay(
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5),
        alignment: .bottom
    )
}

private struct prefsPicker<Content: View>: View {
    @Binding var selection: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        Picker("", selection: $selection) {
            content()
        }
        .pickerStyle(.menu)
        .frame(width: 140)
    }
}

// MARK: - macOS Toggle (CSS .toggle)

struct MacOSToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            let newValue = !isOn
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn = newValue
                }
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(isOn ? Color(red: 0x34/255, green: 0xc7/255, blue: 0x59/255) : Color.white.opacity(0.18))
                    .frame(width: 38, height: 22)

                Circle()
                    .fill(.white)
                    .frame(width: 19, height: 19)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    .padding(1.5)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
