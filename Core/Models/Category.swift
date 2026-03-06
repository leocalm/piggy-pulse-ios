import Foundation

struct CategoryListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let categoryType: String
    let isArchived: Bool
    let isSystem: Bool
}
