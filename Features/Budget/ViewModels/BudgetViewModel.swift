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
            targets = dataStore.targets
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
        let body = BatchUpsertTargetsRequest(
            periodId: periodId,
            targets: [.init(categoryId: categoryId, budgetedValue: value)]
        )
        do {
            try await apiClient.request(.upsertCategoryTargets, body: body)
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
