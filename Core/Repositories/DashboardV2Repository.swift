import Foundation

@MainActor
final class DashboardV2Repository {
    private let dataStore: EncryptedDataStore

    init(dataStore: EncryptedDataStore) {
        self.dataStore = dataStore
    }

    func computeCurrentPeriod(period: BudgetPeriod) -> DashboardCurrentPeriod {
        let spent = dataStore.totalSpent
        let budgeted = dataStore.totalBudgeted
        let incomeTarget = dataStore.targets
            .filter { $0.type == "income" && !$0.isExcluded }
            .reduce(Int64(0)) { $0 + Int64($1.budgetedValue) }

        let daysInPeriod = max(period.length, 1)
        let daysRemaining = period.remainingDays ?? 0
        let elapsed = max(daysInPeriod - daysRemaining, 1)
        let projectedSpend = (spent * Int64(daysInPeriod)) / Int64(elapsed)

        return DashboardCurrentPeriod(
            spent: spent,
            target: budgeted,
            incomeTarget: incomeTarget,
            daysRemaining: daysRemaining,
            daysInPeriod: daysInPeriod,
            projectedSpend: projectedSpend
        )
    }

    func computeNetPosition() -> DashboardNetPosition {
        let accounts = dataStore.accounts.filter { $0.status == "active" }
        let liquid = accounts.filter { $0.type == "Checking" || $0.type == "Wallet" }
            .reduce(Int64(0)) { $0 + $1.currentBalance }
        let protected = accounts.filter { $0.type == "Savings" }
            .reduce(Int64(0)) { $0 + $1.currentBalance }
        let debt = accounts.filter { $0.type == "CreditCard" }
            .reduce(Int64(0)) { $0 + abs(min(0, $1.currentBalance)) }
        let total = dataStore.totalNetWorth
        let income = dataStore.totalIncome
        let spent = dataStore.totalSpent
        let difference = income - spent

        return DashboardNetPosition(
            total: total,
            differenceThisPeriod: difference,
            numberOfAccounts: accounts.count,
            liquidAmount: liquid,
            protectedAmount: protected,
            debtAmount: debt
        )
    }

    func computeCashFlow() -> DashboardCashFlow {
        DashboardCashFlow(
            inflows: dataStore.totalIncome,
            outflows: dataStore.totalSpent,
            net: dataStore.totalIncome - dataStore.totalSpent
        )
    }

    func computeTopVendors(limit: Int = 5) -> [TopVendorItem] {
        dataStore.spendingByVendor()
            .prefix(limit)
            .map { TopVendorItem(vendorId: $0.vendorId, vendorName: $0.name, totalSpent: $0.spent, transactionCount: $0.count) }
    }

    func computeFixedCategories() -> DashboardFixedCategories {
        let fixedTargets = dataStore.targets.filter { !$0.isExcluded }
        let fixedCategoryIds = Set(
            dataStore.categories
                .filter { $0.behavior == "fixed" }
                .map { $0.id }
        )

        var spentByCategory: [UUID: Int64] = [:]
        for tx in dataStore.periodTransactions where tx.category.type == "expense" {
            if fixedCategoryIds.contains(tx.category.id) {
                spentByCategory[tx.category.id, default: 0] += abs(tx.amount)
            }
        }

        let categories = fixedTargets
            .filter { fixedCategoryIds.contains($0.categoryId) }
            .map { target in
                let paid = spentByCategory[target.categoryId] ?? 0
                let budgeted = Int64(target.budgetedValue)
                let status: String
                if paid >= budgeted { status = "paid" }
                else if paid > 0 { status = "partial" }
                else { status = "pending" }
                return FixedCategoryItem(id: target.categoryId, name: target.name, budgeted: budgeted, paid: paid, status: status)
            }

        return DashboardFixedCategories(
            totalBudgeted: categories.reduce(0) { $0 + $1.budgeted },
            totalPaid: categories.reduce(0) { $0 + $1.paid },
            categories: categories
        )
    }

    func computeVariableCategories() -> DashboardVariableCategories {
        let variableCategoryIds = Set(
            dataStore.categories
                .filter { $0.behavior == "variable" && $0.status == "active" }
                .map { $0.id }
        )

        var spentByCategory: [UUID: Int64] = [:]
        for tx in dataStore.periodTransactions where tx.category.type == "expense" {
            if variableCategoryIds.contains(tx.category.id) {
                spentByCategory[tx.category.id, default: 0] += abs(tx.amount)
            }
        }

        let categories = dataStore.targets
            .filter { variableCategoryIds.contains($0.categoryId) && !$0.isExcluded }
            .map { target in
                let cat = dataStore.categories.first { $0.id == target.categoryId }
                return VariableCategoryItem(
                    id: target.categoryId,
                    name: target.name,
                    icon: cat?.icon ?? "📁",
                    budgeted: Int64(target.budgetedValue),
                    spent: spentByCategory[target.categoryId] ?? 0
                )
            }

        return DashboardVariableCategories(
            totalBudgeted: categories.reduce(0) { $0 + $1.budgeted },
            totalSpent: categories.reduce(0) { $0 + $1.spent },
            categories: categories
        )
    }

    func computeSubscriptions() -> DashboardSubscriptions {
        let active = dataStore.subscriptions.filter { $0.status == .active }
        let monthlyTotal = dataStore.monthlySubscriptionTotal
        let yearlyTotal = monthlyTotal * 12

        let items = active
            .sorted { $0.nextChargeDate < $1.nextChargeDate }
            .map { sub in
                SubscriptionDashboardItem(
                    id: sub.id,
                    name: sub.name,
                    billingAmount: sub.billingAmount,
                    billingCycle: sub.billingCycle.rawValue,
                    nextChargeDate: sub.nextChargeDate,
                    displayStatus: "upcoming"
                )
            }

        return DashboardSubscriptions(
            activeCount: active.count,
            monthlyTotal: monthlyTotal,
            yearlyTotal: yearlyTotal,
            subscriptions: items
        )
    }

    func computeRecentTransactions(limit: Int = 5) -> [Transaction] {
        Array(
            dataStore.periodTransactions
                .sorted { $0.date > $1.date }
                .prefix(limit)
        )
    }
}
