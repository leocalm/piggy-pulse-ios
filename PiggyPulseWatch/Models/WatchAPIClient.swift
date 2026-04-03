import Foundation
import Security

// MARK: - Watch Keychain

enum WatchKeychainHelper {

    private static let accessGroup = "com.piggypulse.shared"

    enum Key: String {
        case accessToken = "com.piggypulse.watch.accessToken"
        case currencyCode = "com.piggypulse.watch.currencyCode"
    }

    static func save(_ value: String, for key: Key) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clearAll() {
        delete(.accessToken)
        delete(.currencyCode)
    }
}

// MARK: - Watch API Client

final class WatchAPIClient {

    static let shared = WatchAPIClient()

    private let baseURL = "https://api.piggy-pulse.com/v2"

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
        WatchKeychainHelper.read(.accessToken) != nil
    }

    func setAccessToken(_ token: String) {
        WatchKeychainHelper.save(token, for: .accessToken)
    }

    func clearAuth() {
        WatchKeychainHelper.clearAll()
    }

    // MARK: - API Methods

    func fetchCurrentPeriod() async throws -> WatchCurrentPeriod {
        try await get("/dashboard/current-period")
    }

    func fetchNetPosition() async throws -> WatchNetPosition {
        try await get("/dashboard/net-position")
    }

    func fetchAccounts() async throws -> [WatchAccountSummary] {
        try await get("/accounts")
    }

    func fetchUserInfo() async throws -> WatchUserInfo {
        try await get("/auth/me")
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let token = WatchKeychainHelper.read(.accessToken) else {
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
            WatchKeychainHelper.clearAll()
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
