import Foundation

// MARK: - V2 Dashboard Models

struct DashboardCurrentPeriod: Codable {
    let spent: Int64
    let target: Int64
    let incomeTarget: Int64
    let daysRemaining: Int
    let daysInPeriod: Int
    let projectedSpend: Int64
}

struct DashboardNetPosition: Codable {
    let total: Int64
    let differenceThisPeriod: Int64
    let numberOfAccounts: Int
    let liquidAmount: Int64
    let protectedAmount: Int64
    let debtAmount: Int64
}

struct DashboardCashFlow: Codable {
    let inflows: Int64
    let outflows: Int64
    let net: Int64
}

struct SpendingTrendItem: Codable {
    let periodId: UUID
    let periodName: String
    let totalSpent: Int64
}

struct DashboardSpendingTrend: Codable {
    let periods: [SpendingTrendItem]
    let periodAverage: Int64
}

struct TopVendorItem: Codable {
    let vendorId: UUID
    let vendorName: String
    let totalSpent: Int64
    let transactionCount: Int
}

// API returns the wrapped shape via ?responseFormat=wrapped
struct FixedCategoryItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let budgeted: Int64
    let paid: Int64
    let status: String // "paid", "partial", "pending"
}

struct DashboardFixedCategories: Codable {
    let totalBudgeted: Int64
    let totalPaid: Int64
    let categories: [FixedCategoryItem]
}

struct VariableCategoryItem: Codable {
    let id: UUID
    let name: String
    let icon: String
    let budgeted: Int64
    let spent: Int64
}

struct DashboardVariableCategories: Codable {
    let totalBudgeted: Int64
    let totalSpent: Int64
    let categories: [VariableCategoryItem]
}

struct SubscriptionDashboardItem: Codable {
    let id: UUID
    let name: String
    let billingAmount: Int64
    let billingCycle: String // "monthly", "quarterly", "yearly"
    let nextChargeDate: String
    let displayStatus: String // "charged", "today", "upcoming"
}

struct DashboardSubscriptions: Codable {
    let activeCount: Int
    let monthlyTotal: Int64
    let yearlyTotal: Int64
    let subscriptions: [SubscriptionDashboardItem]
}

struct DashboardBudgetStabilityV2: Codable {
    let stability: Int
    let periodsWithinRange: Int
    let periodsStability: [Bool]
}

struct RecentTransactionItem: Codable {
    let id: UUID
    let description: String?
    let amount: Int64
    let date: String
    let categoryName: String?
    let categoryIcon: String?
    let vendorName: String?
    let transactionType: String // "income", "expense", "transfer"
}

// MARK: - Categories Overview (used by Variable Categories widget)

struct CategoriesOverviewSummaryItem: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let type: String // "income", "expense"
    let status: String // "active", "inactive"
    let actual: Int64
    let projected: Int64
    let budgeted: Int64?
    let variance: Int64
}

struct CategoriesOverviewSummary: Codable {
    let periodName: String
    let periodElapsedPercent: Int64
    let totalSpent: Int64
    let totalBudgeted: Int64?
    let totalBudgetedIncoming: Int64?
    let variance: Int64
}

struct CategoriesOverviewResponse: Codable {
    let summary: CategoriesOverviewSummary
    let categories: [CategoriesOverviewSummaryItem]
}
