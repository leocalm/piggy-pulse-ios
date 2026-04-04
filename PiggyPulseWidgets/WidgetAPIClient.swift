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

    static func fetchActivePeriodId() async throws -> UUID {
        // Check if we have a cached period ID
        if let cached = WidgetTokenStore.read(.periodId), let id = UUID(uuidString: cached) {
            return id
        }
        let response: WidgetPaginatedResponse<WidgetPeriod> = try await get("/periods?limit=100")
        guard let period = response.data.first(where: { $0.status == "active" }) ?? response.data.first else {
            throw URLError(.badServerResponse)
        }
        WidgetTokenStore.save(period.id.uuidString, for: .periodId)
        return period.id
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

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(T.self, from: data)
    }
}
