import Foundation

struct AccountListItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
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

    init(id: UUID, name: String, color: String, icon: String = "💰", type: String, status: String,
         currentBalance: Int64, spendLimit: Int32? = nil,
         netChangeThisPeriod: Int64 = 0, numberOfTransactions: Int64 = 0,
         nextTransfer: String? = nil, balanceAfterNextTransfer: Int64? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.type = type
        self.status = status
        self.currentBalance = currentBalance
        self.spendLimit = spendLimit
        self.netChangeThisPeriod = netChangeThisPeriod
        self.numberOfTransactions = numberOfTransactions
        self.nextTransfer = nextTransfer
        self.balanceAfterNextTransfer = balanceAfterNextTransfer
    }
}

struct AccountsSummary {
    let totalNetWorth: Int64
    let totalAssets: Int64
    let totalLiabilities: Int64
}

extension AccountListItem: Hashable {
    static func == (lhs: AccountListItem, rhs: AccountListItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
