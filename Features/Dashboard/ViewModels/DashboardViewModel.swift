import SwiftUI
internal import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var burnIn: MonthlyBurnIn?
    @Published var progress: MonthProgress?
    @Published var netPosition: NetPosition?
    @Published var stability: BudgetStability?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let repository: DashboardRepository

    init(apiClient: APIClient) {
        self.repository = DashboardRepository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        async let burnInTask = repository.fetchBurnIn(periodId: periodId)
        async let progressTask = repository.fetchProgress(periodId: periodId)
        async let netPositionTask = repository.fetchNetPosition(periodId: periodId)
        async let stabilityTask = repository.fetchStability()

        do {
            let (b, p, n, s) = try await (burnInTask, progressTask, netPositionTask, stabilityTask)
            burnIn = b
            progress = p
            netPosition = n
            stability = s
        } catch {
            errorMessage = "Failed to load dashboard data."
        }

        isLoading = false
    }
}
