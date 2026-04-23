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
    @Published var hasSchedule = false

    private var repository: PeriodRepository?
    private var dataStore: EncryptedDataStore?

    init() {}

    func configure(apiClient: APIClient, dataStore: EncryptedDataStore) {
        guard repository == nil else { return }
        repository = PeriodRepository(apiClient: apiClient)
        self.dataStore = dataStore
    }

    func load() async {
        guard let repository else { return }
        isLoading = true
        errorMessage = nil

        async let periodsTask = repository.fetchPeriods()
        async let scheduleTask = repository.fetchScheduleExists()

        do {
            let all = try await periodsTask

            // Enrich active period with transaction count from dataStore
            let txCount = dataStore?.periodTransactions.count ?? 0
            currentPeriod = all.first(where: { $0.periodStatus == .active }).map { period in
                BudgetPeriod(
                    id: period.id, name: period.name, startDate: period.startDate,
                    periodType: period.periodType, length: period.length,
                    remainingDays: period.remainingDays,
                    numberOfTransactions: txCount,
                    percentageOfTargetUsed: period.percentageOfTargetUsed,
                    status: period.status,
                    totalSpent: dataStore?.totalSpent ?? period.totalSpent,
                    totalBudgeted: dataStore?.totalBudgeted ?? period.totalBudgeted
                )
            }
            upcomingPeriods = all.filter { $0.periodStatus == .upcoming }
            pastPeriods = all.filter { $0.periodStatus == .ended }.reversed()
        } catch {
            errorMessage = String(localized: "Failed to load periods.")
        }

        hasSchedule = await scheduleTask

        isLoading = false
    }
}
