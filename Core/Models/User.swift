import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let timezone: String?
    let defaultCurrency: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, timezone
        case defaultCurrency = "default_currency"
    }
}
