import Foundation

struct BudgetCategoryItem: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let budgetedValue: Int32
    let category: BudgetCategoryDetail
}

struct BudgetCategoryDetail: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let categoryType: String
    let isArchived: Bool
    let isSystem: Bool
}
