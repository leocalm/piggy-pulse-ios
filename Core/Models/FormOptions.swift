import Foundation

struct CategoryOption: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let categoryType: String
}

struct AccountOption: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
}

struct VendorOption: Codable, Identifiable {
    let id: UUID
    let name: String
}
