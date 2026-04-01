import Foundation

struct VendorListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let status: String               // "active" | "inactive"
    let numberOfTransactions: Int64
    let totalSpend: Int64

    // MARK: - Backward compatibility

    var archived: Bool { status == "inactive" }
    var transactionCount: Int64 { numberOfTransactions }
}

extension VendorListItem: Hashable {
    static func == (lhs: VendorListItem, rhs: VendorListItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
