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
            URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased()),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let dirValue = direction.queryValue {
            queryItems.append(URLQueryItem(name: "direction", value: dirValue))
        }

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor.uuidString.lowercased()))
        }

        for id in accountIds {
            queryItems.append(URLQueryItem(name: "account_id", value: id.uuidString.lowercased()))
        }

        for id in categoryIds {
            queryItems.append(URLQueryItem(name: "category_id", value: id.uuidString.lowercased()))
        }

        for id in vendorIds {
            queryItems.append(URLQueryItem(name: "vendor_id", value: id.uuidString.lowercased()))
        }

        return try await apiClient.request(.transactions, queryItems: queryItems)
    }
}
