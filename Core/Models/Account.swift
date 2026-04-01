import Foundation

struct AccountListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let type: String              // "Checking" | "Savings" | "CreditCard" | "Allowance" | "Wallet"
    let status: String            // "active" | "inactive"
    let currentBalance: Int64
    let netChangeThisPeriod: Int64
    let numberOfTransactions: Int64
    let nextTransfer: String?
    let balanceAfterNextTransfer: Int64?
    let spendLimit: Int32?

    // MARK: - Backward compatibility

    var accountType: String { type }
    var balance: Int64 { currentBalance }
    var isArchived: Bool { status == "inactive" }
    var balanceChangeThisPeriod: Int64 { netChangeThisPeriod }
    var transactionCount: Int64 { numberOfTransactions }
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
