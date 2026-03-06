import SwiftUI
internal import Combine

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedDirection: TransactionDirection = .all

    private var nextCursor: UUID?
    private var hasMore = true
    private var currentPeriodId: UUID?
    private let repository: TransactionRepository

    init(apiClient: APIClient) {
        self.repository = TransactionRepository(apiClient: apiClient)
    }

    func load(periodId: UUID) async {
        currentPeriodId = periodId
        isLoading = true
        errorMessage = nil
        transactions = []
        nextCursor = nil
        hasMore = true

        do {
            let response = try await repository.fetchTransactions(
                periodId: periodId,
                direction: selectedDirection
            )
            transactions = response.data
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
        } catch {
            errorMessage = "Failed to load transactions."
        }

        isLoading = false
    }

    func loadMore() async {
        guard let periodId = currentPeriodId,
              let cursor = nextCursor,
              hasMore,
              !isLoadingMore else { return }

        isLoadingMore = true

        do {
            let response = try await repository.fetchTransactions(
                periodId: periodId,
                direction: selectedDirection,
                cursor: cursor
            )
            transactions.append(contentsOf: response.data)
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
        } catch {
            // Silently fail on load more — user can scroll again
        }

        isLoadingMore = false
    }

    func refresh(periodId: UUID) async {
        await load(periodId: periodId)
    }

    func changeDirection(_ direction: TransactionDirection, periodId: UUID) async {
        selectedDirection = direction
        await load(periodId: periodId)
    }
}
