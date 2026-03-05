import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let onboardingStatus: String
}
