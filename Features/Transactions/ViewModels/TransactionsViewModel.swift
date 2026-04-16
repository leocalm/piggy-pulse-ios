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
            transactions = response.data
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
        guard let repository,
              !isLoadingFilterOptions &&
              filterOptions.accounts.isEmpty &&
              filterOptions.categories.isEmpty &&
              filterOptions.vendors.isEmpty else { return }

        isLoadingFilterOptions = true
        defer { isLoadingFilterOptions = false }

        async let accounts: [AccountOption] = (try? repository.apiClient.request(.accountOptions)) ?? []
        async let categories: [CategoryOption] = (try? repository.apiClient.request(.categoryOptions)) ?? []

        var allVendors: [VendorOption] = []
        var vendorCursor: String? = nil
        repeat {
            var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "100")]
            if let cursor = vendorCursor {
                queryItems.append(URLQueryItem(name: "cursor", value: cursor))
            }
            if let page: PaginatedResponse<VendorOption> = try? await repository.apiClient.request(.vendors, queryItems: queryItems) {
                allVendors.append(contentsOf: page.data)
                vendorCursor = page.nextCursor
            } else {
                break
            }
        } while vendorCursor != nil

        let (a, c) = await (accounts, categories)
        filterOptions = TransactionFilterOptions(accounts: a, categories: c, vendors: allVendors)
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
