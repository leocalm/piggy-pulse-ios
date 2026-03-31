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
        try await apiClient.request(.dashboardVariableCategories, queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)])
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
