import SwiftUI
internal import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var burnIn: DashboardCurrentPeriod?
    @Published var targets: [CategoryTarget] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private var apiClient: APIClient?
    private var dataStore: EncryptedDataStore?
    private var dashboardRepo: DashboardV2Repository?

    init() {}

    func configure(apiClient: APIClient, dataStore: EncryptedDataStore) {
        guard self.apiClient == nil else { return }
        self.apiClient = apiClient
        self.dataStore = dataStore
        self.dashboardRepo = DashboardV2Repository(dataStore: dataStore)
    }

    // MARK: - Load

    func load(periodId: UUID, period: BudgetPeriod? = nil) async {
        guard let dataStore, let dashboardRepo else { return }
        isLoading = true
        errorMessage = nil

        do {
            if !dataStore.isLoaded {
                try await dataStore.loadAll(periodId: periodId)
            }

            // Merge categories with existing targets so every category appears
            let existingTargets = dataStore.targets
            let targetByCategoryId = Dictionary(uniqueKeysWithValues: existingTargets.map { ($0.categoryId, $0) })

            targets = dataStore.categories
                .filter { $0.status == "active" && $0.type != "transfer" }
                .map { cat in
                    if let existing = targetByCategoryId[cat.id] {
                        return existing
                    }
                    // Category without a target — show with zero budget
                    return CategoryTarget(
                        id: cat.id, categoryId: cat.id,
                        name: cat.name, type: cat.type, parentId: cat.parentId,
                        budgetedValue: 0, isExcluded: false
                    )
                }

            if let period {
                burnIn = dashboardRepo.computeCurrentPeriod(period: period)
            }
        } catch {
            errorMessage = String(localized: "Failed to load budget data.")
        }

        isLoading = false
    }

    // MARK: - Mutations

    func setTarget(categoryId: UUID, value: Int32, periodId: UUID) async {
        guard let apiClient else { return }
        isSaving = true
        do {
            // Check if a real target (from API) exists — real targets have id != categoryId
            let existingTarget = dataStore?.targets.first(where: { $0.categoryId == categoryId })
            if let existing = existingTarget {
                try await apiClient.request(
                    .updateCategoryTarget(existing.id),
                    body: UpdateTargetRequest(value: Int64(value))
                )
            } else {
                try await apiClient.request(
                    .createCategoryTarget,
                    body: CreateTargetRequest(categoryId: categoryId, value: Int64(value))
                )
            }
            dataStore?.clear()
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to save target.")
        }
        isSaving = false
    }

    func excludeTarget(id: UUID, periodId: UUID) async {
        guard let apiClient else { return }
        isSaving = true
        do {
            try await apiClient.request(.excludeCategoryTarget(id))
            dataStore?.clear()
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to exclude category.")
        }
        isSaving = false
    }

    func includeTarget(id: UUID, periodId: UUID) async {
        guard let apiClient else { return }
        isSaving = true
        do {
            try await apiClient.request(.includeCategoryTarget(id))
            dataStore?.clear()
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to re-include category.")
        }
        isSaving = false
    }
}
