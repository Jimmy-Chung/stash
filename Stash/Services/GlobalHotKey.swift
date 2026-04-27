import Carbon
import AppKit

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private let handler: () -> Void
    private static var nextID: UInt32 = 1

    init(keyboardShortcut: KeyboardShortcut, handler: @escaping () -> Void) {
        self.handler = handler
        register(keyboardShortcut: keyboardShortcut)
    }

    deinit {
        unregister()
    }

    struct KeyboardShortcut {
        let keyCode: UInt32
        let modifiers: UInt32

        static let commandShiftV = KeyboardShortcut(
            keyCode: 0x09, // V key
            modifiers: UInt32(cmdKey | shiftKey)
        )
    }

    private func register(keyboardShortcut: KeyboardShortcut) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x53544348), id: Self.nextID)
        Self.nextID += 1

        let status = RegisterEventHotKey(
            keyboardShortcut.keyCode,
            keyboardShortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else { return }

        // Install event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                hotKey.handler()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
