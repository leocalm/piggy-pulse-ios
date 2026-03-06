import SwiftUI
internal import Combine

@MainActor
final class PeriodsViewModel: ObservableObject {
    @Published var currentPeriod: BudgetPeriod?
    @Published var upcomingPeriods: [BudgetPeriod] = []
    @Published var pastPeriods: [BudgetPeriod] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showPastPeriods = false

    private let repository: PeriodRepository

    init(apiClient: APIClient) {
        self.repository = PeriodRepository(apiClient: apiClient)
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let all = try await repository.fetchPeriods()

            currentPeriod = all.first(where: { $0.status == .active })
            upcomingPeriods = all.filter { $0.status == .upcoming }
            pastPeriods = all.filter { $0.status == .ended }.reversed()
        } catch {
            errorMessage = "Failed to load periods."
        }

        isLoading = false
    }
}
