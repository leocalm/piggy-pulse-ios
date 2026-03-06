import Foundation

struct VendorListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let archived: Bool
    let transactionCount: Int64
}
