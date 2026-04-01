import Foundation

struct ProfileResponse: Codable {
    let name: String
    let email: String?
    let currency: String?
    let avatar: String?
    let timezone: String?
    let defaultCurrencyId: UUID?
}

struct PreferencesResponse: Codable {
    let theme: String
    let dateFormat: String
    let numberFormat: String
    let language: String?
    let compactMode: Bool?
    let dashboardLayout: DashboardLayoutPrefs?
    let colorTheme: String?
}

struct DashboardLayoutPrefs: Codable {
    let widgetOrder: [String]?
    let hiddenWidgets: [String]?
    let visibleAccountIds: [String]?
}
