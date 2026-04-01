import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let currency: String?
    let twoFactorEnabled: Bool?
    let onboardingStatus: String?
}
