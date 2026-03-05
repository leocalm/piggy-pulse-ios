import Foundation

final class PeriodRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPeriods() async throws -> [BudgetPeriod] {
        let response: PaginatedResponse<BudgetPeriod> = try await apiClient.request(.periods)
        return response.data
    }
}
