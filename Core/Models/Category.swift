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

extension CategoryManagementItem: Hashable {
    static func == (lhs: CategoryManagementItem, rhs: CategoryManagementItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
