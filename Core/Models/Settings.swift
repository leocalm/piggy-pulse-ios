import Foundation

struct ProfileResponse: Codable {
    let name: String
    let email: String
    let timezone: String
    let defaultCurrencyId: UUID?
}

struct PreferencesResponse: Codable {
    let theme: String
    let dateFormat: String
    let numberFormat: String
}
