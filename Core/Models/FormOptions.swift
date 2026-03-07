import Foundation

struct CategoryOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let categoryType: String
}

struct AccountOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
}

struct VendorOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
}
