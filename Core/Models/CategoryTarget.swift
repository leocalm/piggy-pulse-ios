import Foundation

struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: String            // "income" | "expense" | "transfer"
    let parentId: UUID?
    let previousTarget: Int32?
    let currentTarget: Int32?   // cents; nil means no target set
    let projectedVariance: Int64
    let status: String          // "active" | "excluded"
    let spentInPeriod: Int64    // cents; actual spending for this category in the period

    // MARK: - Backward compatibility

    var categoryId: UUID { id }
    var categoryName: String { name }
    var categoryType: String { type }
    var categoryIcon: String { "" }     // Not in v2 TargetItem — callers should not rely on this
    var categoryColor: String { "" }    // Not in v2 TargetItem — callers should not rely on this
    var spentAmount: Int64? { spentInPeriod }
    var isExcluded: Bool { status == "excluded" }
    var exclusionReason: String? { nil }
}

struct TargetSummary: Codable {
    let periodName: String
    let periodStart: String
    let periodEnd: String?
    let currentPosition: Int64
    let incomeTarget: Int64
    let categoriesWithTargets: CategoriesWithTargets
    let periodProgress: Int

    struct CategoriesWithTargets: Codable {
        let withTargets: Int
        let total: Int
    }
}

struct CategoryTargetsResponse: Codable {
    let summary: TargetSummary
    let targets: [CategoryTarget]

    // MARK: - Backward compatibility

    var allTargets: [CategoryTarget] { targets }
}

struct BatchUpsertTargetsRequest: Encodable {
    struct TargetItem: Encodable {
        let categoryId: UUID
        let budgetedValue: Int32
    }
    let periodId: UUID
    let targets: [TargetItem]
}
