import Foundation

final class DashboardRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    private func periodQuery(_ periodId: UUID) -> [URLQueryItem] {
        [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
    }

    func fetchBurnIn(periodId: UUID) async throws -> MonthlyBurnIn {
        try await apiClient.request(.monthlyBurnIn, queryItems: periodQuery(periodId))
    }

    func fetchProgress(periodId: UUID) async throws -> MonthProgress {
        try await apiClient.request(.monthProgress, queryItems: periodQuery(periodId))
    }

    func fetchNetPosition(periodId: UUID) async throws -> NetPosition {
        try await apiClient.request(.netPosition, queryItems: periodQuery(periodId))
    }

    func fetchStability() async throws -> BudgetStability {
        try await apiClient.request(.budgetStability)
    }

    func fetchTopCategories(periodId: UUID) async throws -> [CategorySpending] {
        try await apiClient.request(.topCategories, queryItems: periodQuery(periodId))
    }

    func fetchRecentTransactions(periodId: UUID) async throws -> [Transaction] {
        try await apiClient.request(.recentTransactions, queryItems: periodQuery(periodId))
    }

    func fetchBalanceOverTime() async throws -> [BalanceDataPoint] {
        try await apiClient.request(.balanceOverTime)
    }

    func fetchCategoryBreakdown(categoryId: UUID, periodId: UUID) async throws -> [CategoryBreakdownItem] {
        try await apiClient.request(.categoryBreakdown(categoryId), queryItems: periodQuery(periodId))
    }

    func fetchAccountSnapshot(accountId: UUID, periodId: UUID) async throws -> AccountListItem {
        try await apiClient.request(.accountSnapshot(accountId), queryItems: periodQuery(periodId))
    }

    // MARK: - Dashboard Layout

    func fetchLayout() async throws -> [DashboardCardConfig] {
        try await apiClient.request(.dashboardLayout)
    }

    func createCard(_ request: CreateDashboardCardRequest) async throws -> DashboardCardConfig {
        try await apiClient.request(.createDashboardCard, body: request)
    }

    func updateCard(_ id: UUID, _ request: UpdateDashboardCardRequest) async throws -> DashboardCardConfig {
        try await apiClient.request(.updateDashboardCard(id), body: request)
    }

    func reorderCards(_ request: ReorderRequest) async throws -> [DashboardCardConfig] {
        try await apiClient.request(.reorderDashboardCards, body: request)
    }

    func deleteCard(_ id: UUID) async throws {
        try await apiClient.requestVoid(.deleteDashboardCard(id))
    }

    func fetchAvailableCards() async throws -> AvailableCardsResponse {
        try await apiClient.request(.availableCards)
    }

    func resetLayout() async throws -> [DashboardCardConfig] {
        try await apiClient.request(.resetDashboardLayout)
    }
}
