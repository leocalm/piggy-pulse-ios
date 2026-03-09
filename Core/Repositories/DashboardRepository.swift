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
}
