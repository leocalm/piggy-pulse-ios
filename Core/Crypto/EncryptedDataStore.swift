import SwiftUI
internal import Combine

@MainActor
final class EncryptedDataStore: ObservableObject {
    @Published var accounts: [AccountListItem] = []
    @Published var categories: [CategoryListItem] = []
    @Published var vendors: [VendorListItem] = []
    @Published var subscriptions: [Subscription] = []
    @Published var targets: [CategoryTarget] = []
    @Published var periodTransactions: [Transaction] = []
    @Published var isLoaded = false

    private let apiClient: APIClient
    private let decryptionService: DecryptionService

    init(apiClient: APIClient, decryptionService: DecryptionService) {
        self.apiClient = apiClient
        self.decryptionService = decryptionService
    }

    func loadAll(periodId: UUID) async throws {
        async let accountsTask: [EncryptedAccount] = apiClient.request(.accounts)
        async let categoriesTask: [EncryptedCategory] = apiClient.request(.categories)
        async let vendorsTask: [EncryptedVendor] = apiClient.request(.vendors)
        async let subscriptionsTask: [EncryptedSubscription] = apiClient.request(.subscriptions)
        async let targetsTask: [EncryptedTarget] = apiClient.request(.categoryTargets, queryItems: [
            URLQueryItem(name: "periodId", value: periodId.uuidString)
        ])
        async let transactionsTask: EncryptedTransactionsResponse = apiClient.request(.transactions, queryItems: [
            URLQueryItem(name: "periodId", value: periodId.uuidString),
            URLQueryItem(name: "limit", value: "10000"),
        ])

        let (encAccounts, encCategories, encVendors, encSubscriptions, encTargets, encTransactions) =
            try await (accountsTask, categoriesTask, vendorsTask, subscriptionsTask, targetsTask, transactionsTask)

        accounts = try decryptionService.decrypt(encAccounts)
        categories = try decryptionService.decrypt(encCategories)
        vendors = try decryptionService.decrypt(encVendors)
        subscriptions = try decryptionService.decrypt(encSubscriptions)

        targets = try encTargets.map { try decryptionService.decrypt($0, categories: categories) }

        periodTransactions = try decryptionService.decryptTransactions(
            encTransactions.data,
            accounts: accounts,
            categories: categories,
            vendors: vendors
        )

        isLoaded = true
    }

    func clear() {
        accounts = []
        categories = []
        vendors = []
        subscriptions = []
        targets = []
        periodTransactions = []
        isLoaded = false
    }

    // MARK: - Local computation (replaces retired server endpoints)

    var totalNetWorth: Int64 {
        accounts
            .filter { $0.status == "active" }
            .reduce(0) { $0 + $1.currentBalance }
    }

    var totalAssets: Int64 {
        accounts
            .filter { $0.status == "active" && $0.type != "CreditCard" }
            .reduce(0) { $0 + max(0, $1.currentBalance) }
    }

    var totalLiabilities: Int64 {
        accounts
            .filter { $0.status == "active" && $0.type == "CreditCard" }
            .reduce(0) { $0 + abs(min(0, $1.currentBalance)) }
    }

    var totalSpent: Int64 {
        periodTransactions
            .filter { $0.category.type == "expense" }
            .reduce(0) { $0 + abs($1.amount) }
    }

    var totalIncome: Int64 {
        periodTransactions
            .filter { $0.category.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    var totalBudgeted: Int64 {
        targets
            .filter { !$0.isExcluded }
            .reduce(0) { $0 + Int64($1.budgetedValue) }
    }

    func spendingByCategory() -> [(categoryId: UUID, name: String, icon: String, color: String, spent: Int64)] {
        var grouped: [UUID: Int64] = [:]
        for tx in periodTransactions where tx.category.type == "expense" {
            grouped[tx.category.id, default: 0] += abs(tx.amount)
        }
        return grouped.compactMap { catId, spent in
            guard let cat = categories.first(where: { $0.id == catId }) else { return nil }
            return (catId, cat.name, cat.icon, cat.color, spent)
        }.sorted { $0.spent > $1.spent }
    }

    func spendingByVendor() -> [(vendorId: UUID, name: String, spent: Int64, count: Int)] {
        var grouped: [UUID: (spent: Int64, count: Int)] = [:]
        for tx in periodTransactions {
            guard let vendor = tx.vendor else { continue }
            let existing = grouped[vendor.id] ?? (0, 0)
            grouped[vendor.id] = (existing.spent + abs(tx.amount), existing.count + 1)
        }
        return grouped.compactMap { vendorId, data in
            guard let vendor = vendors.first(where: { $0.id == vendorId }) else { return nil }
            return (vendorId, vendor.name, data.spent, data.count)
        }.sorted { $0.spent > $1.spent }
    }

    func upcomingSubscriptions() -> [Subscription] {
        subscriptions
            .filter { $0.status == .active }
            .sorted { $0.nextChargeDate < $1.nextChargeDate }
    }

    var monthlySubscriptionTotal: Int64 {
        subscriptions
            .filter { $0.status == .active }
            .reduce(0) { total, sub in
                switch sub.billingCycle {
                case .monthly: return total + sub.billingAmount
                case .quarterly: return total + sub.billingAmount / 3
                case .yearly: return total + sub.billingAmount / 12
                }
            }
    }
}
