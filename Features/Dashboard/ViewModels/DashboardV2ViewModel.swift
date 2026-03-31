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
    @Published var recentTransactions: [Transaction]?

    @Published var isLoading = true
    @Published var errorMessage: String?

    let layout = DashboardLayout()
    private var repository: DashboardV2Repository?

    init(apiClient: APIClient) {
        self.repository = DashboardV2Repository(apiClient: apiClient)
    }

    init() {}

    func configure(apiClient: APIClient) {
        guard repository == nil else { return }
        repository = DashboardV2Repository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        guard let repository else { return }
        isLoading = true
        errorMessage = nil

        // Load all widget data concurrently using async let.
        // Each widget handles its own failure gracefully.
        async let cpTask: DashboardCurrentPeriod? = Self.tryFetch { try await repository.fetchCurrentPeriod(periodId: periodId) }
        async let npTask: DashboardNetPosition? = Self.tryFetch { try await repository.fetchNetPosition(periodId: periodId) }
        async let cfTask: DashboardCashFlow? = Self.tryFetch { try await repository.fetchCashFlow(periodId: periodId) }
        async let stTask: DashboardSpendingTrend? = Self.tryFetch { try await repository.fetchSpendingTrend(periodId: periodId) }
        async let tvTask: [TopVendorItem]? = Self.tryFetch { try await repository.fetchTopVendors(periodId: periodId) }
        async let vcTask: DashboardVariableCategories? = Self.tryFetch { try await repository.fetchVariableCategories(periodId: periodId) }
        async let fcTask: DashboardFixedCategories? = Self.tryFetch { try await repository.fetchFixedCategories(periodId: periodId) }
        async let subTask: DashboardSubscriptions? = Self.tryFetch { try await repository.fetchSubscriptions(periodId: periodId) }
        async let bsTask: DashboardBudgetStabilityV2? = Self.tryFetch { try await repository.fetchBudgetStability(periodId: periodId) }
        async let rtTask: [Transaction]? = Self.tryFetch { try await repository.fetchRecentTransactions(periodId: periodId) }

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

    /// Try an async fetch, returning nil on failure instead of throwing.
    private static func tryFetch<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
        try? await work()
    }
}
