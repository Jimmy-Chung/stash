import Foundation
import Combine
import ServiceManagement

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    // General
    @Published var launchAtLogin: Bool = false
    @Published var showMenuBarIcon: Bool = true
    @Published var historyLimit: Int = 500
    @Published var soundEnabled: Bool = true

    // Shortcuts
    @Published var globalHotKeyModifiers: UInt32 = 0
    @Published var globalHotKeyCode: UInt32 = 9

    // Appearance
    @Published var appearanceMode: Int = 0
    @Published var blurAmount: Double = 50.0
    @Published var cardDensity: Int = 1

    // Behavior
    @Published var autoHideOnFocusLoss: Bool = true

    // Wallpaper Theme
    @Published var wallpaperTheme: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load from UserDefaults
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

        // Debounced save to UserDefaults (saves 0.5s after last change)
        $launchAtLogin
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "launchAtLogin") }
            .store(in: &cancellables)

        $showMenuBarIcon
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "showMenuBarIcon") }
            .store(in: &cancellables)

        $historyLimit
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "historyLimit") }
            .store(in: &cancellables)

        $soundEnabled
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "soundEnabled") }
            .store(in: &cancellables)

        $globalHotKeyModifiers
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "globalHotKeyModifiers") }
            .store(in: &cancellables)

        $globalHotKeyCode
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "globalHotKeyCode") }
            .store(in: &cancellables)

        $appearanceMode
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "appearanceMode") }
            .store(in: &cancellables)

        $blurAmount
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { UserDefaults.standard.set($0, forKey: "blurAmount") }
            .store(in: &cancellables)

        $cardDensity
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink {
                UserDefaults.standard.set($0, forKey: "cardDensity")
                NotificationCenter.default.post(name: NSNotification.Name("cardDensityDidChange"), object: nil)
            }
            .store(in: &cancellables)

        $autoHideOnFocusLoss
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink {
                UserDefaults.standard.set($0, forKey: "autoHideOnFocusLoss")
                NotificationCenter.default.post(name: NSNotification.Name("autoHideOnFocusLossDidChange"), object: nil)
            }
            .store(in: &cancellables)

        $wallpaperTheme
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink {
                UserDefaults.standard.set($0, forKey: "wallpaperTheme")
                NotificationCenter.default.post(name: NSNotification.Name("wallpaperThemeDidChange"), object: nil)
            }
            .store(in: &cancellables)

        // Special handling for launchAtLogin SMAppService
        $launchAtLogin
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { enabled in
                DispatchQueue.global(qos: .userInitiated).async {
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
            .store(in: &cancellables)
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


    var density: CardDensity {
        CardDensity(rawValue: cardDensity) ?? .normal
    }

    var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }
}
