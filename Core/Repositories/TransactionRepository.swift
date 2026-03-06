import Foundation

final class TransactionRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchTransactions(
        periodId: UUID,
        direction: TransactionDirection = .all,
        cursor: UUID? = nil,
        limit: Int = 20
    ) async throws -> CursorPaginatedTransactions {
        var queryItems = [
            URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased()),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let dirValue = direction.queryValue {
            queryItems.append(URLQueryItem(name: "direction", value: dirValue))
        }

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor.uuidString.lowercased()))
        }

        return try await apiClient.request(.transactions, queryItems: queryItems)
    }
}
