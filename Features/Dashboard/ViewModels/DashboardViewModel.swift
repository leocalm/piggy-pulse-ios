import SwiftUI
internal import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    // Layout
    @Published var layout: [DashboardCardConfig] = []

    // Existing card data
    @Published var burnIn: MonthlyBurnIn?
    @Published var progress: MonthProgress?
    @Published var netPosition: NetPosition?
    @Published var stability: BudgetStability?

    // New card data
    @Published var topCategories: [CategorySpending] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var balanceOverTime: [BalanceDataPoint] = []
    @Published var categoryBreakdowns: [UUID: [CategoryBreakdownItem]] = [:]
    @Published var accountSnapshots: [UUID: AccountListItem] = [:]
    @Published var entityNames: [UUID: String] = [:]

    @Published var isLoading = true
    @Published var errorMessage: String?

    let repository: DashboardRepository

    init(apiClient: APIClient) {
        self.repository = DashboardRepository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            layout = try await repository.fetchLayout()
            try await loadEntityNames(for: layout.visibleCards)
            try await fetchCardData(for: layout.visibleCards, periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to load dashboard data.")
        }

        isLoading = false
    }

    private func fetchCardData(
        for cards: [DashboardCardConfig],
        periodId: UUID
    ) async throws {
        let enabledTypes = Set(cards.map(\.cardType))

        try await withThrowingTaskGroup(of: Void.self) { group in
            let needsBurnIn = !enabledTypes.isDisjoint(with: [.currentPeriod, .budgetPerDay, .remainingBudget])
            if needsBurnIn {
                group.addTask {
                    async let b = self.repository.fetchBurnIn(periodId: periodId)
                    async let p = self.repository.fetchProgress(periodId: periodId)
                    let (burnIn, progress) = try await (b, p)
                    await MainActor.run {
                        self.burnIn = burnIn
                        self.progress = progress
                    }
                }
            }
            if enabledTypes.contains(.budgetStability) {
                group.addTask {
                    let s = try await self.repository.fetchStability()
                    await MainActor.run { self.stability = s }
                }
            }
            if enabledTypes.contains(.netPosition) {
                group.addTask {
                    let n = try await self.repository.fetchNetPosition(periodId: periodId)
                    await MainActor.run { self.netPosition = n }
                }
            }
            if enabledTypes.contains(.topCategories) {
                group.addTask {
                    let cats = try await self.repository.fetchTopCategories(periodId: periodId)
                    await MainActor.run { self.topCategories = cats }
                }
            }
            if enabledTypes.contains(.recentTransactions) {
                group.addTask {
                    let txs = try await self.repository.fetchRecentTransactions(periodId: periodId)
                    await MainActor.run { self.recentTransactions = txs }
                }
            }
            if enabledTypes.contains(.balanceOverTime) {
                group.addTask {
                    let pts = try await self.repository.fetchBalanceOverTime()
                    await MainActor.run { self.balanceOverTime = pts }
                }
            }

            // Entity cards
            for card in cards {
                switch card.cardType {
                case .accountSummary:
                    if let entityId = card.entityId {
                        group.addTask {
                            let acct = try await self.repository.fetchAccountSnapshot(accountId: entityId, periodId: periodId)
                            await MainActor.run { self.accountSnapshots[entityId] = acct }
                        }
                    }
                case .categoryBreakdown:
                    if let entityId = card.entityId {
                        group.addTask {
                            let items = try await self.repository.fetchCategoryBreakdown(categoryId: entityId, periodId: periodId)
                            await MainActor.run { self.categoryBreakdowns[entityId] = items }
                        }
                    }
                default:
                    break
                }
            }

            try await group.waitForAll()
        }
    }

    private func loadEntityNames(for cards: [DashboardCardConfig]) async throws {
        let hasEntityCards = cards.contains { $0.cardType.isEntityCard && $0.entityId != nil }
        guard hasEntityCards else { return }

        let available = try await repository.fetchAvailableCards()
        for group in available.entityCards {
            for entity in group.availableEntities {
                entityNames[entity.id] = entity.name
            }
        }
    }

    // MARK: - Layout Mutations

    func reorderCards(_ reorder: ReorderRequest) async throws {
        layout = try await repository.reorderCards(reorder)
    }

    func toggleCard(_ cardId: UUID, enabled: Bool) async throws {
        let updated = try await repository.updateCard(cardId, UpdateDashboardCardRequest(
            position: nil, enabled: enabled
        ))
        if let idx = layout.firstIndex(where: { $0.id == cardId }) {
            layout[idx] = updated
        }
    }

    @discardableResult
    func addCard(_ request: CreateDashboardCardRequest) async throws -> DashboardCardConfig {
        let newCard = try await repository.createCard(request)
        layout.append(newCard)
        return newCard
    }

    func deleteCard(_ cardId: UUID) async throws {
        try await repository.deleteCard(cardId)
        layout.removeAll { $0.id == cardId }
    }

    func resetLayout() async throws {
        layout = try await repository.resetLayout()
    }
}
