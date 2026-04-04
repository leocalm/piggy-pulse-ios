import Foundation

// MARK: - Widget Models

struct WidgetCurrentPeriod: Codable {
    let spent: Int64
    let target: Int64
    let daysRemaining: Int
    let daysInPeriod: Int
    let projectedSpend: Int64
}

struct WidgetNetPosition: Codable {
    let total: Int64
    let differenceThisPeriod: Int64
    let numberOfAccounts: Int
    let liquidAmount: Int64
    let protectedAmount: Int64
    let debtAmount: Int64
}

struct WidgetPeriod: Codable {
    let id: UUID
    let name: String
    let status: String
}

struct WidgetPaginatedResponse<T: Codable>: Codable {
    let data: [T]
}

// MARK: - Widget API Client

enum WidgetAPIClient {

    #if DEBUG
    private static let baseURL = "http://192.168.1.148:8000/v2"
    #else
    private static let baseURL = "https://api.piggy-pulse.com/v2"
    #endif

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    // MARK: - API Methods

    /// Shared resolved period ID for the current refresh cycle (avoids duplicate /periods calls)
    private static var resolvedPeriodId: UUID?

    static func fetchActivePeriodId() async throws -> UUID {
        // Return already-resolved ID for this refresh cycle
        if let resolved = resolvedPeriodId { return resolved }

        // Always fetch fresh from API — period can change between refreshes
        let response: WidgetPaginatedResponse<WidgetPeriod> = try await get("/periods?limit=100")
        guard let period = response.data.first(where: { $0.status == "active" }) ?? response.data.first else {
            throw URLError(.badServerResponse)
        }
        resolvedPeriodId = period.id
        return period.id
    }

    /// Reset the per-cycle cache (call at start of each timeline refresh)
    static func resetCache() {
        resolvedPeriodId = nil
    }

    static func fetchCurrentPeriod(periodId: UUID) async throws -> WidgetCurrentPeriod {
        try await get("/dashboard/current-period?periodId=\(periodId.uuidString)")
    }

    static func fetchNetPosition(periodId: UUID) async throws -> WidgetNetPosition {
        try await get("/dashboard/net-position?periodId=\(periodId.uuidString)")
    }

    // MARK: - Private

    private static func get<T: Decodable>(_ path: String) async throws -> T {
        guard let token = WidgetTokenStore.read(.accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            WidgetTokenStore.clearAll()
            throw URLError(.userAuthenticationRequired)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(T.self, from: data)
    }
}
