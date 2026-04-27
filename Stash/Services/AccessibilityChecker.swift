import ApplicationServices
import AppKit

enum AccessibilityChecker {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
