import SwiftUI
internal import Combine

@MainActor
final class DashboardV2ViewModel: ObservableObject {
    @Published var currentPeriod: DashboardCurrentPeriod?
    @Published var netPosition: DashboardNetPosition?
    @Published var cashFlow: DashboardCashFlow?
    @Published var spendingTrend: DashboardSpendingTrend?
    @Published var topVendors: [TopVendorItem]?
    @Published var variableCategories: DashboardVariableCategories?
    @Published var fixedCategories: DashboardFixedCategories?
    @Published var subscriptions: DashboardSubscriptions?
    @Published var budgetStability: DashboardBudgetStabilityV2?
    @Published var recentTransactions: [Transaction]?
    @Published var accounts: [AccountListItem]?

    @Published var isLoading = true
    @Published var errorMessage: String?

    let layout = DashboardLayout()
    private var repository: DashboardV2Repository?
    private var dataStore: EncryptedDataStore?

    init() {}

    func configure(dataStore: EncryptedDataStore) {
        guard repository == nil else { return }
        self.dataStore = dataStore
        self.repository = DashboardV2Repository(dataStore: dataStore)
    }

    func load(period: BudgetPeriod) async {
        guard let repository, let dataStore else {
            errorMessage = String(localized: "dashboard.loadError")
            isLoading = false
            return
        }

        if currentPeriod == nil {
            isLoading = true
        }
        errorMessage = nil

        if !dataStore.isLoaded {
            do {
                try await dataStore.loadAll(periodId: period.id)
            } catch {
                errorMessage = String(localized: "dashboard.loadError")
                isLoading = false
                return
            }
        }

        currentPeriod = repository.computeCurrentPeriod(period: period)
        netPosition = repository.computeNetPosition()
        cashFlow = repository.computeCashFlow()
        topVendors = repository.computeTopVendors()
        variableCategories = repository.computeVariableCategories()
        fixedCategories = repository.computeFixedCategories()
        subscriptions = repository.computeSubscriptions()
        recentTransactions = repository.computeRecentTransactions()
        // Enrich accounts with transaction counts and net change from period data
        var txCountByAccount: [UUID: Int64] = [:]
        var netChangeByAccount: [UUID: Int64] = [:]
        for tx in dataStore.periodTransactions {
            txCountByAccount[tx.fromAccount.id, default: 0] += 1
            netChangeByAccount[tx.fromAccount.id, default: 0] -= abs(tx.amount)
            if let toAccount = tx.toAccount {
                txCountByAccount[toAccount.id, default: 0] += 1
                netChangeByAccount[toAccount.id, default: 0] += abs(tx.amount)
            }
            if tx.category.type == "income" {
                netChangeByAccount[tx.fromAccount.id, default: 0] += abs(tx.amount) * 2 // undo the subtract above, add the income
            }
        }
        accounts = dataStore.accounts.filter { $0.status == "active" }.map { acct in
            AccountListItem(
                id: acct.id, name: acct.name, color: acct.color, icon: acct.icon,
                type: acct.type, status: acct.status,
                currentBalance: acct.currentBalance, spendLimit: acct.spendLimit,
                netChangeThisPeriod: netChangeByAccount[acct.id] ?? 0,
                numberOfTransactions: txCountByAccount[acct.id] ?? 0
            )
        }

        isLoading = false
    }
}
