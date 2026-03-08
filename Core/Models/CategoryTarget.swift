import Foundation

struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let targetValue: Int32   // cents; 0 means "no target set"
    let excluded: Bool
}

struct CategoryTargetsResponse: Codable {
    let periodId: UUID
    let targets: [CategoryTarget]
}

struct BatchUpsertTargetsRequest: Encodable {
    struct TargetItem: Encodable {
        let categoryId: UUID
        let targetValue: Int32
    }
    let periodId: UUID
    let targets: [TargetItem]
}
