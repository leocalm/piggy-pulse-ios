import SwiftUI
internal import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var burnIn: MonthlyBurnIn?
    @Published var categories: [BudgetCategoryItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let burnInTask: MonthlyBurnIn = apiClient.request(
                .monthlyBurnIn,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            async let categoriesTask: PaginatedResponse<BudgetCategoryItem> = apiClient.request(.budgetCategories)

            let (b, c) = try await (burnInTask, categoriesTask)
            burnIn = b
            categories = c.data
        } catch {
            errorMessage = "Failed to load budget data."
        }

        isLoading = false
    }
}
