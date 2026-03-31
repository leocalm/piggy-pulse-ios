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
    @Published var accounts: [AccountListItem]?

    @Published var isLoading = true
    @Published var errorMessage: String?

    let layout = DashboardLayout()
    private(set) var apiClient: APIClient?
    private var repository: DashboardV2Repository?

    init() {}

    func configure(apiClient: APIClient) {
        guard repository == nil else { return }
        self.apiClient = apiClient
        repository = DashboardV2Repository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        guard let repository, let apiClient else {
            errorMessage = String(localized: "dashboard.loadError")
            isLoading = false
            return
        }

        // Only show loading shimmer on first load
        if currentPeriod == nil {
            isLoading = true
        }
        errorMessage = nil

        // Load each widget independently — failures don't block others
        currentPeriod = try? await repository.fetchCurrentPeriod(periodId: periodId)
        netPosition = try? await repository.fetchNetPosition(periodId: periodId)
        cashFlow = try? await repository.fetchCashFlow(periodId: periodId)
        spendingTrend = try? await repository.fetchSpendingTrend(periodId: periodId)
        topVendors = try? await repository.fetchTopVendors(periodId: periodId)
        variableCategories = try? await repository.fetchVariableCategories(periodId: periodId)
        fixedCategories = try? await repository.fetchFixedCategories(periodId: periodId)
        subscriptions = try? await repository.fetchSubscriptions(periodId: periodId)
        budgetStability = try? await repository.fetchBudgetStability(periodId: periodId)
        recentTransactions = try? await repository.fetchRecentTransactions(periodId: periodId)

        let acctResp: PaginatedResponse<AccountListItem>? = try? await apiClient.request(
            .accountsSummary,
            queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)]
        )
        accounts = acctResp?.data

        // Only show error if ALL core requests failed on initial load
        if currentPeriod == nil && netPosition == nil && cashFlow == nil {
            errorMessage = String(localized: "dashboard.loadError")
        }

        isLoading = false
    }
}
