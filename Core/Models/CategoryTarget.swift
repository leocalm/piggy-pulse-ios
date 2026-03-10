import Foundation

struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let categoryType: String
    let categoryIcon: String
    let categoryColor: String
    let currentTarget: Int32?   // cents; nil means no target set
    let previousTarget: Int32?
    let spentAmount: Int64?     // cents; actual spending for this category in the period
    let isExcluded: Bool
    let exclusionReason: String?
}

struct CategoryTargetsResponse: Codable {
    let periodId: UUID
    let outgoingTargets: [CategoryTarget]
    let incomingTargets: [CategoryTarget]
    let excludedCategories: [CategoryTarget]

    var allTargets: [CategoryTarget] {
        outgoingTargets + incomingTargets + excludedCategories
    }
}

struct BatchUpsertTargetsRequest: Encodable {
    struct TargetItem: Encodable {
        let categoryId: UUID
        let budgetedValue: Int32
    }
    let periodId: UUID
    let targets: [TargetItem]
}
