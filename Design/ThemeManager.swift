import SwiftUI

/// Manages the active color theme and appearance mode.
/// Injected into the SwiftUI environment via `.environment(themeManager)`.
@Observable
@MainActor
final class ThemeManager {
    private static let themeKey = "ppColorTheme"
    private static let modeKey = "appTheme"

    // MARK: - Published State

    var colorTheme: ColorTheme {
        didSet {
            UserDefaults.standard.set(colorTheme.rawValue, forKey: Self.themeKey)
        }
    }

    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.modeKey)
        }
    }

    // MARK: - Derived

    var accents: ThemeAccents { colorTheme.accents }

    var primary: Color { accents.primary }
    var secondary: Color { accents.secondary }
    var tertiary: Color { accents.tertiary }
    var destructive: Color { accents.destructive }
    var gradient: [Color] { accents.gradient }

    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .light: return .light
        case .dark:  return .dark
        case .system: return nil
        }
    }

    // MARK: - Shared

    static let shared = ThemeManager()

    // MARK: - Init

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeKey) ?? ColorTheme.nebula.rawValue
        self.colorTheme = ColorTheme(rawValue: storedTheme) ?? .nebula

        let storedMode = UserDefaults.standard.string(forKey: Self.modeKey) ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: storedMode) ?? .system
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return String(localized: "appearance.system")
        case .light:  return String(localized: "appearance.light")
        case .dark:   return String(localized: "appearance.dark")
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Environment Key

extension EnvironmentValues {
    @Entry var themeManager: ThemeManager = .shared
}
