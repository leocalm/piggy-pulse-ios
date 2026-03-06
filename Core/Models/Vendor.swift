import Foundation

struct VendorListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let archived: Bool
    let transactionCount: Int64
}

extension VendorListItem: Hashable {
    static func == (lhs: VendorListItem, rhs: VendorListItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
