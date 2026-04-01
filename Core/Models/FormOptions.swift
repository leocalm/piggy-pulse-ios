import Foundation

struct CategoryOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let color: String

    // MARK: - Backward compatibility
    var categoryType: String { "" }  // Not in v2 CategoryOptionResponse
}

struct AccountOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: String
}

struct VendorOption: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
}
