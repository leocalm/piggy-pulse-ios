import SwiftUI
internal import Combine

struct TransactionFilterOptions {
    var accounts: [AccountOption] = []
    var categories: [CategoryOption] = []
    var vendors: [VendorOption] = []
}

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedDirection: TransactionDirection = .all
    @Published var selectedAccountIds: Set<UUID> = []
    @Published var selectedCategoryIds: Set<UUID> = []
    @Published var selectedVendorIds: Set<UUID> = []
    @Published var filterOptions = TransactionFilterOptions()
    @Published var isLoadingFilterOptions = false

    private var nextCursor: UUID?
    private var hasMore = true
    private var currentPeriodId: UUID?
    private var repository: TransactionRepository?
    private var dataStore: EncryptedDataStore?

    init(apiClient: APIClient, decryptionService: DecryptionService) {
        self.repository = TransactionRepository(apiClient: apiClient, decryptionService: decryptionService)
    }

    init() {}

    func configure(apiClient: APIClient, decryptionService: DecryptionService, dataStore: EncryptedDataStore) {
        guard repository == nil else { return }
        repository = TransactionRepository(apiClient: apiClient, decryptionService: decryptionService)
        self.dataStore = dataStore
    }

    var activeFilterCount: Int {
        selectedAccountIds.count + selectedCategoryIds.count + selectedVendorIds.count
    }

    func load(periodId: UUID) async {
        guard let repository, let dataStore else { return }
        currentPeriodId = periodId
        isLoading = true
        errorMessage = nil
        transactions = []
        nextCursor = nil
        hasMore = true

        // Ensure reference data is loaded for category/vendor/account lookups
        if !dataStore.isLoaded {
            try? await dataStore.loadAll(periodId: periodId)
        }

        do {
            let response = try await repository.fetchTransactions(
                periodId: periodId,
                direction: selectedDirection,
                accountIds: Array(selectedAccountIds),
                categoryIds: Array(selectedCategoryIds),
                vendorIds: Array(selectedVendorIds),
                accounts: dataStore.accounts,
                categories: dataStore.categories,
                vendors: dataStore.vendors
            )
            var filtered = response.data

            // Client-side filtering (API returns all transactions)
            if let dirValue = selectedDirection.queryValue {
                filtered = filtered.filter { tx in
                    switch dirValue {
                    case "income": return tx.category.type == "income"
                    case "expense": return tx.category.type == "expense"
                    case "transfer": return tx.toAccount != nil
                    default: return true
                    }
                }
            }
            if !selectedAccountIds.isEmpty {
                filtered = filtered.filter { tx in
                    selectedAccountIds.contains(tx.fromAccount.id) ||
                    (tx.toAccount.map { selectedAccountIds.contains($0.id) } ?? false)
                }
            }
            if !selectedCategoryIds.isEmpty {
                filtered = filtered.filter { selectedCategoryIds.contains($0.category.id) }
            }
            if !selectedVendorIds.isEmpty {
                filtered = filtered.filter { tx in
                    tx.vendor.map { selectedVendorIds.contains($0.id) } ?? false
                }
            }

            transactions = filtered
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
        } catch {
            errorMessage = String(localized: "Failed to load transactions.")
        }

        isLoading = false
    }

    func loadMore() async {
        guard let repository, let dataStore,
              let periodId = currentPeriodId,
              let cursor = nextCursor,
              hasMore,
              !isLoadingMore else { return }

        isLoadingMore = true

        do {
            let response = try await repository.fetchTransactions(
                periodId: periodId,
                direction: selectedDirection,
                cursor: cursor,
                accountIds: Array(selectedAccountIds),
                categoryIds: Array(selectedCategoryIds),
                vendorIds: Array(selectedVendorIds),
                accounts: dataStore.accounts,
                categories: dataStore.categories,
                vendors: dataStore.vendors
            )
            transactions.append(contentsOf: response.data)
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
        } catch {
            // Silently fail on load more
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

    func loadFilterOptions() async {
        guard !isLoadingFilterOptions &&
              filterOptions.accounts.isEmpty &&
              filterOptions.categories.isEmpty &&
              filterOptions.vendors.isEmpty,
              let dataStore else { return }

        isLoadingFilterOptions = true
        defer { isLoadingFilterOptions = false }

        // Build filter options from already-decrypted data in the data store
        let accounts = dataStore.accounts.map { AccountOption(id: $0.id, name: $0.name, color: $0.color) }
        let categories = dataStore.categories
            .filter { $0.status == "active" }
            .map { CategoryOption(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color) }
        let vendors = dataStore.vendors
            .filter { $0.status == "active" }
            .map { VendorOption(id: $0.id, name: $0.name) }

        filterOptions = TransactionFilterOptions(accounts: accounts, categories: categories, vendors: vendors)
    }

    func applyFilters(
        accountIds: Set<UUID>,
        categoryIds: Set<UUID>,
        vendorIds: Set<UUID>,
        periodId: UUID
    ) async {
        selectedAccountIds = accountIds
        selectedCategoryIds = categoryIds
        selectedVendorIds = vendorIds
        await load(periodId: periodId)
    }

    func clearFilters(periodId: UUID) async {
        selectedAccountIds = []
        selectedCategoryIds = []
        selectedVendorIds = []
        await load(periodId: periodId)
    }
}
