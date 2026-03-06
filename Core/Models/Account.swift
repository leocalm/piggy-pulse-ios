import Foundation

struct AccountListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let accountType: String
    let balance: Int64
    let spendLimit: Int32?
    let isArchived: Bool
    let balanceChangeThisPeriod: Int64
    let transactionCount: Int64
}

struct AccountsSummary: Codable {
    let totalNetWorth: Int64
    let totalAssets: Int64
    let totalLiabilities: Int64
}

extension AccountListItem: Hashable {
    static func == (lhs: AccountListItem, rhs: AccountListItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
