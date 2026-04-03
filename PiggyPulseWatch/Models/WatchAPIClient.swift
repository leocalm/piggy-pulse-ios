import Foundation
import Security

// MARK: - Watch Token Storage (App Group UserDefaults — shared with widget extension)

enum WatchTokenStore {

    static let appGroupId = "group.com.piggypulse.watch"
    private static let defaults = UserDefaults(suiteName: appGroupId) ?? .standard

    enum Key: String {
        case accessToken = "com.piggypulse.watch.accessToken"
        case currencyCode = "com.piggypulse.watch.currencyCode"
    }

    static func save(_ value: String, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static func read(_ key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    static func delete(_ key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }

    static func clearAll() {
        delete(.accessToken)
        delete(.currencyCode)
    }
}

// Keep old name as typealias for compatibility
typealias WatchKeychainHelper = WatchTokenStore

// MARK: - Watch API Client

final class WatchAPIClient {

    static let shared = WatchAPIClient()

    #if DEBUG
    private let baseURL = "http://192.168.1.148:8000/v2"
    #else
    private let baseURL = "https://api.piggy-pulse.com/v2"
    #endif

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Auth

    var isAuthenticated: Bool {
        WatchTokenStore.read(.accessToken) != nil
    }

    func setAccessToken(_ token: String) {
        WatchTokenStore.save(token, for: .accessToken)
    }

    func clearAuth() {
        WatchTokenStore.clearAll()
    }

    // MARK: - API Methods

    func fetchPeriods() async throws -> [WatchPeriod] {
        let response: PaginatedResponse<WatchPeriod> = try await get("/periods?limit=100")
        return response.data
    }

    func fetchCurrentPeriod(periodId: UUID) async throws -> WatchCurrentPeriod {
        try await get("/dashboard/current-period?periodId=\(periodId.uuidString)")
    }

    func fetchNetPosition(periodId: UUID) async throws -> WatchNetPosition {
        try await get("/dashboard/net-position?periodId=\(periodId.uuidString)")
    }

    func fetchAccounts() async throws -> [WatchAccountSummary] {
        let response: PaginatedResponse<WatchAccountSummary> = try await get("/accounts?limit=100")
        return response.data
    }

    func fetchUserInfo() async throws -> WatchUserInfo {
        try await get("/auth/me")
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let token = WatchTokenStore.read(.accessToken) else {
            throw WatchAPIError.unauthorized
        }

        guard let url = URL(string: baseURL + path) else {
            throw WatchAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchAPIError.networkError
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            WatchTokenStore.clearAll()
            throw WatchAPIError.unauthorized
        case 404:
            throw WatchAPIError.notFound
        default:
            throw WatchAPIError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Errors

enum WatchAPIError: LocalizedError {
    case unauthorized
    case invalidURL
    case networkError
    case notFound
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return String(localized: "Please open PiggyPulse on your iPhone to sign in.")
        case .invalidURL:
            return String(localized: "Invalid request URL.")
        case .networkError:
            return String(localized: "Unable to connect. Check your connection.")
        case .notFound:
            return String(localized: "Data not found.")
        case .serverError(let code):
            return String(localized: "Server error (\(code)). Try again later.")
        case .decodingError:
            return String(localized: "Unexpected response format.")
        }
    }
}
