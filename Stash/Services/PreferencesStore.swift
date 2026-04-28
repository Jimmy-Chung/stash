import Foundation
import Combine
import ServiceManagement

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    // General
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            let enabled = launchAtLogin
            DispatchQueue.main.async {
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("SMAppService error: \(error)")
                }
            }
        }
    }
    @Published var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }
    @Published var historyLimit: Int {
        didSet { UserDefaults.standard.set(historyLimit, forKey: "historyLimit") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    // Shortcuts
    @Published var globalHotKeyModifiers: UInt32 {
        didSet { UserDefaults.standard.set(globalHotKeyModifiers, forKey: "globalHotKeyModifiers") }
    }
    @Published var globalHotKeyCode: UInt32 {
        didSet { UserDefaults.standard.set(globalHotKeyCode, forKey: "globalHotKeyCode") }
    }

    // Appearance
    @Published var appearanceMode: Int {
        didSet { UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode") }
    }
    @Published var blurAmount: Double {
        didSet { UserDefaults.standard.set(blurAmount, forKey: "blurAmount") }
    }
    @Published var cardDensity: Int {
        didSet { UserDefaults.standard.set(cardDensity, forKey: "cardDensity") }
    }

    // Behavior
    @Published var autoHideOnFocusLoss: Bool {
        didSet { UserDefaults.standard.set(autoHideOnFocusLoss, forKey: "autoHideOnFocusLoss") }
    }

    // Wallpaper Theme
    @Published var wallpaperTheme: Int {
        didSet { UserDefaults.standard.set(wallpaperTheme, forKey: "wallpaperTheme") }
    }

    enum AppearanceMode: Int {
        case system = 0, light = 1, dark = 2
    }

    enum CardDensity: Int {
        case compact = 0, normal = 1, cozy = 2

        var cardWidth: CGFloat {
            switch self {
            case .compact: return 240
            case .normal: return 268
            case .cozy: return 290
            }
        }

        var cardHeight: CGFloat {
            switch self {
            case .compact: return 240
            case .normal: return 268
            case .cozy: return 290
            }
        }

        var displayName: String {
            switch self {
            case .compact: return "Compact"
            case .normal: return "Default"
            case .cozy: return "Cozy"
            }
        }
    }

    init() {
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
        self.showMenuBarIcon = UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true
        self.historyLimit = UserDefaults.standard.object(forKey: "historyLimit") as? Int ?? 500
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.globalHotKeyModifiers = UserDefaults.standard.object(forKey: "globalHotKeyModifiers") as? UInt32 ?? 0
        self.globalHotKeyCode = UserDefaults.standard.object(forKey: "globalHotKeyCode") as? UInt32 ?? 9
        self.appearanceMode = UserDefaults.standard.object(forKey: "appearanceMode") as? Int ?? 0
        self.blurAmount = UserDefaults.standard.object(forKey: "blurAmount") as? Double ?? 50.0
        self.cardDensity = UserDefaults.standard.object(forKey: "cardDensity") as? Int ?? 1
        self.autoHideOnFocusLoss = UserDefaults.standard.object(forKey: "autoHideOnFocusLoss") as? Bool ?? true
        self.wallpaperTheme = UserDefaults.standard.object(forKey: "wallpaperTheme") as? Int ?? 0
    }

    var density: CardDensity {
        CardDensity(rawValue: cardDensity) ?? .normal
    }

    var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }
}
