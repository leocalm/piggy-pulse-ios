import Foundation
import WidgetKit

/// Shared token store accessible by both the main app and the widget extension.
/// Uses App Group UserDefaults for cross-process access.
enum WidgetTokenStore {

    static let appGroupId = "group.com.piggypulse.ios"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    enum Key: String {
        case accessToken = "com.piggypulse.widget.accessToken"
        case currencyCode = "com.piggypulse.widget.currencyCode"
        case colorTheme = "com.piggypulse.widget.colorTheme"
    }

    static func save(_ value: String, for key: Key) {
        defaults?.set(value, forKey: key.rawValue)
    }

    static func read(_ key: Key) -> String? {
        defaults?.string(forKey: key.rawValue)
    }

    static func clearAll() {
        let d = defaults
        d?.removeObject(forKey: Key.accessToken.rawValue)
        d?.removeObject(forKey: Key.currencyCode.rawValue)
        // Keep colorTheme on logout — widgets still look nice themed
    }

    /// Called from the main app to sync auth state to widgets.
    static func syncFromApp(token: String, currencyCode: String) {
        save(token, for: .accessToken)
        save(currencyCode, for: .currencyCode)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Called on logout to clear widget data.
    static func clearAndReload() {
        clearAll()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
