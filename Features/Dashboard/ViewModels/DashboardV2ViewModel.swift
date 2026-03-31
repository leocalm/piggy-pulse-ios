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
    @Published var recentTransactions: [RecentTransactionItem]?

    @Published var isLoading = true
    @Published var errorMessage: String?

    let layout = DashboardLayout()
    private let repository: DashboardV2Repository

    init(apiClient: APIClient) {
        self.repository = DashboardV2Repository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        // Load all widget data concurrently using async let.
        // Each widget handles its own failure gracefully.
        async let cpTask: DashboardCurrentPeriod? = tryFetch { try await self.repository.fetchCurrentPeriod(periodId: periodId) }
        async let npTask: DashboardNetPosition? = tryFetch { try await self.repository.fetchNetPosition(periodId: periodId) }
        async let cfTask: DashboardCashFlow? = tryFetch { try await self.repository.fetchCashFlow(periodId: periodId) }
        async let stTask: DashboardSpendingTrend? = tryFetch { try await self.repository.fetchSpendingTrend(periodId: periodId) }
        async let tvTask: [TopVendorItem]? = tryFetch { try await self.repository.fetchTopVendors(periodId: periodId) }
        async let vcTask: DashboardVariableCategories? = tryFetch { try await self.repository.fetchVariableCategories(periodId: periodId) }
        async let fcTask: DashboardFixedCategories? = tryFetch { try await self.repository.fetchFixedCategories(periodId: periodId) }
        async let subTask: DashboardSubscriptions? = tryFetch { try await self.repository.fetchSubscriptions(periodId: periodId) }
        async let bsTask: DashboardBudgetStabilityV2? = tryFetch { try await self.repository.fetchBudgetStability(periodId: periodId) }
        async let rtTask: [RecentTransactionItem]? = tryFetch { try await self.repository.fetchRecentTransactions(periodId: periodId).data }

        currentPeriod = await cpTask
        netPosition = await npTask
        cashFlow = await cfTask
        spendingTrend = await stTask
        topVendors = await tvTask
        variableCategories = await vcTask
        fixedCategories = await fcTask
        subscriptions = await subTask
        budgetStability = await bsTask
        recentTransactions = await rtTask

        // Only show error if ALL core requests failed
        if currentPeriod == nil && netPosition == nil && cashFlow == nil {
            errorMessage = String(localized: "dashboard.loadError")
        }

        isLoading = false
    }
}

/// Try an async fetch, returning nil on failure instead of throwing.
private func tryFetch<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
    try? await work()
}
