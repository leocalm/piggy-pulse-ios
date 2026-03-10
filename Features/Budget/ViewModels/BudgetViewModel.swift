import SwiftUI
internal import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var burnIn: MonthlyBurnIn?
    @Published var targets: [CategoryTarget] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let burnInTask: MonthlyBurnIn = apiClient.request(
                .monthlyBurnIn,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            async let targetsTask: CategoryTargetsResponse = apiClient.request(
                .categoryTargets,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )

            let (b, t) = try await (burnInTask, targetsTask)
            burnIn = b
            targets = t.allTargets
        } catch {
            errorMessage = String(localized: "Failed to load budget data.")
        }

        isLoading = false
    }

    // MARK: - Mutations

    func setTarget(categoryId: UUID, value: Int32, periodId: UUID) async {
        isSaving = true
        let body = BatchUpsertTargetsRequest(
            periodId: periodId,
            targets: [.init(categoryId: categoryId, budgetedValue: value)]
        )
        do {
            try await apiClient.request(.upsertCategoryTargets, body: body)
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to save target.")
        }
        isSaving = false
    }

    func excludeTarget(id: UUID, periodId: UUID) async {
        isSaving = true
        do {
            try await apiClient.request(.excludeCategoryTarget(id))
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to exclude category.")
        }
        isSaving = false
    }

    func includeTarget(id: UUID, periodId: UUID) async {
        isSaving = true
        do {
            try await apiClient.request(.includeCategoryTarget(id))
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to re-include category.")
        }
        isSaving = false
    }
}
