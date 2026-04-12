import Foundation

final class TransactionRepository {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchTransactions(
        periodId: UUID,
        direction: TransactionDirection = .all,
        cursor: UUID? = nil,
        limit: Int = 20,
        accountIds: [UUID] = [],
        categoryIds: [UUID] = [],
        vendorIds: [UUID] = []
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

        return try await apiClient.request(.transactions, queryItems: queryItems)
    }

    func fetchHasAnyTransactions() async throws -> HasTransactionsResponse {
        try await apiClient.request(.transactionsHasAny)
    }
}
