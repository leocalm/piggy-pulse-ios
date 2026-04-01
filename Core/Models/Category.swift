import Foundation

struct CategoryListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let type: String          // "income" | "expense" | "transfer"
    let status: String        // "active" | "inactive"
    let parentId: UUID?
    let behavior: String?     // "fixed" | "variable" | "subscription" | nil

    // MARK: - Backward compatibility

    var categoryType: String { type }
    var isArchived: Bool { status == "inactive" }
    var isSystem: Bool { false }
}

extension CategoryManagementItem: Hashable {
    static func == (lhs: CategoryManagementItem, rhs: CategoryManagementItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
