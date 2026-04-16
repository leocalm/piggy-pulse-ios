import Foundation

final class TransactionRepository {
    let apiClient: APIClient
    let decryptionService: DecryptionService

    init(apiClient: APIClient, decryptionService: DecryptionService) {
        self.apiClient = apiClient
        self.decryptionService = decryptionService
    }

    @MainActor
    func fetchTransactions(
        periodId: UUID,
        direction: TransactionDirection = .all,
        cursor: UUID? = nil,
        limit: Int = 20,
        accountIds: [UUID] = [],
        categoryIds: [UUID] = [],
        vendorIds: [UUID] = [],
        accounts: [AccountListItem],
        categories: [CategoryListItem],
        vendors: [VendorListItem]
    ) async throws -> CursorPaginatedTransactions {
        var queryItems = [
            URLQueryItem(name: "periodId", value: periodId.uuidString),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let dirValue = direction.queryValue {
            queryItems.append(URLQueryItem(name: "direction", value: dirValue))
        }

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor.uuidString))
        }

        for id in accountIds {
            queryItems.append(URLQueryItem(name: "accountId", value: id.uuidString))
        }

        for id in categoryIds {
            queryItems.append(URLQueryItem(name: "categoryId", value: id.uuidString))
        }

        for id in vendorIds {
            queryItems.append(URLQueryItem(name: "vendorId", value: id.uuidString))
        }

        let encrypted: [EncryptedTransaction] = try await apiClient.request(.transactions, queryItems: queryItems)
        let decrypted = try decryptionService.decryptTransactions(
            encrypted,
            accounts: accounts,
            categories: categories,
            vendors: vendors
        )

        return CursorPaginatedTransactions(data: decrypted, nextCursor: nil)
    }

    func fetchHasAnyTransactions() async throws -> HasTransactionsResponse {
        try await apiClient.request(.transactionsHasAny)
    }
}
