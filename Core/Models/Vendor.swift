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

    init(id: UUID, name: String, description: String? = nil, status: String,
         numberOfTransactions: Int64 = 0, totalSpend: Int64 = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.numberOfTransactions = numberOfTransactions
        self.totalSpend = totalSpend
    }
}

extension VendorListItem: Hashable {
    static func == (lhs: VendorListItem, rhs: VendorListItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
