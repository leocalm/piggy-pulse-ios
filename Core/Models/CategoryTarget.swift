import Foundation

struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let name: String
    let type: String            // "income" | "expense" | "transfer"
    let parentId: UUID?
    let budgetedValue: Int32    // cents
    let isExcluded: Bool

    // MARK: - Backward compatibility

    var categoryName: String { name }
    var categoryType: String { type }
    var categoryIcon: String { "" }
    var categoryColor: String { "" }
    var currentTarget: Int32? { budgetedValue }
    var spentAmount: Int64? { nil }
    var spentInPeriod: Int64 { 0 }
    var previousTarget: Int32? { nil }
    var projectedVariance: Int64 { 0 }
    var exclusionReason: String? { nil }
    var status: String { isExcluded ? "excluded" : "active" }

    init(id: UUID, categoryId: UUID, name: String, type: String, parentId: UUID?, budgetedValue: Int32, isExcluded: Bool) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.type = type
        self.parentId = parentId
        self.budgetedValue = budgetedValue
        self.isExcluded = isExcluded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "expense"
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        budgetedValue = try container.decodeIfPresent(Int32.self, forKey: .budgetedValue) ?? 0
        isExcluded = try container.decodeIfPresent(Bool.self, forKey: .isExcluded) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id, categoryId, name, type, parentId, budgetedValue, isExcluded
    }
}

// TargetSummary is no longer returned by the encrypted API — computed locally from decrypted targets + transactions

struct BatchUpsertTargetsRequest: Encodable {
    struct TargetItem: Encodable {
        let categoryId: UUID
        let budgetedValue: Int32
    }
    let periodId: UUID
    let targets: [TargetItem]
}
