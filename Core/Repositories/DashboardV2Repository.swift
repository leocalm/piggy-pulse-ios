import Foundation

final class DashboardV2Repository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCurrentPeriod(periodId: UUID) async throws -> DashboardCurrentPeriod {
        try await apiClient.request(.dashboardCurrentPeriod, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchNetPosition(periodId: UUID) async throws -> DashboardNetPosition {
        try await apiClient.request(.dashboardNetPosition, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchCashFlow(periodId: UUID) async throws -> DashboardCashFlow {
        try await apiClient.request(.dashboardCashFlow, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchSpendingTrend(periodId: UUID) async throws -> DashboardSpendingTrend {
        try await apiClient.request(.dashboardSpendingTrend, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchTopVendors(periodId: UUID) async throws -> [TopVendorItem] {
        try await apiClient.request(.dashboardTopVendors, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchFixedCategories(periodId: UUID) async throws -> DashboardFixedCategories {
        try await apiClient.request(.dashboardFixedCategories, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchVariableCategories(periodId: UUID) async throws -> DashboardVariableCategories {
        // Uses categories overview endpoint (same as web) — no dedicated variable-categories endpoint
        let overview: CategoriesOverviewResponse = try await apiClient.request(.categoriesOverview, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
        let variable = overview.categories.filter { $0.type == "expense" && $0.status == "active" && ($0.budgeted ?? 0) > 0 }
        let totalBudgeted = variable.reduce(Int64(0)) { $0 + ($1.budgeted ?? 0) }
        let totalSpent = variable.reduce(Int64(0)) { $0 + $1.actual }
        return DashboardVariableCategories(
            totalBudgeted: totalBudgeted,
            totalSpent: totalSpent,
            categories: variable.map {
                VariableCategoryItem(id: $0.id, name: $0.name, icon: $0.icon, budgeted: $0.budgeted ?? 0, spent: $0.actual)
            }
        )
    }

    func fetchSubscriptions(periodId: UUID) async throws -> DashboardSubscriptions {
        try await apiClient.request(.dashboardSubscriptions, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchBudgetStability(periodId: UUID) async throws -> DashboardBudgetStabilityV2 {
        try await apiClient.request(.dashboardBudgetStability, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
    }

    func fetchRecentTransactions(periodId: UUID, limit: Int = 5) async throws -> PaginatedResponse<RecentTransactionItem> {
        try await apiClient.request(.dashboardRecentTransactions, queryItems: [
            URLQueryItem(name: "periodId", value: periodId.uuidString),
            URLQueryItem(name: "limit", value: String(limit))
        ])
    }
}
