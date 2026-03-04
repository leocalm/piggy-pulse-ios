import Foundation

final class APIClient {
    static let baseURL = "https://api.piggy-pulse.com/api/v1"

    private let tokenManager: TokenManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let session: URLSession

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Request with no body, expecting a decoded response
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await performRequest(endpoint, body: nil as Empty?, queryItems: queryItems)
        return try decodeResponse(data)
    }

    /// Request with a body, expecting a decoded response
    func request<T: Decodable, B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await performRequest(endpoint, body: body, queryItems: queryItems)
        return try decodeResponse(data)
    }

    /// Request with a body, no response body expected
    func request<B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B
    ) async throws {
        _ = try await performRequest(endpoint, body: body)
    }

    /// Request with no body, no response body expected
    func request(_ endpoint: APIEndpoint) async throws {
        _ = try await performRequest(endpoint, body: nil as Empty?)
    }

    // MARK: - Private

    private struct Empty: Encodable {}

    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performRequest<B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B?,
        queryItems: [URLQueryItem]? = nil,
        isRetry: Bool = false
    ) async throws -> Data {
        var urlComponents = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Auth header
        if endpoint.requiresAuth {
            guard let token = await tokenManager.getAccessToken() else {
                throw APIError.unauthorized
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body = body, !(body is Empty) {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try encoder.encode(body)
        }

        // Execute
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(statusCode: 0, message: "Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data

        case 401:
            if isRetry || !endpoint.requiresAuth {
                await tokenManager.clearTokens()
                throw APIError.unauthorized
            }

            // Try refresh
            do {
                _ = try await refreshAccessToken()
                return try await performRequest(endpoint, body: body, queryItems: queryItems, isRetry: true)
            } catch {
                await tokenManager.clearTokens()
                throw APIError.unauthorized
            }

        case 403:
            // Check if this is a 2FA-required response
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
               let twoFactorToken = errorResponse.twoFactorToken {
                throw APIError.twoFactorRequired(token: twoFactorToken)
            }
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 422:
            let errorResponse = try? decoder.decode(ValidationErrorResponse.self, from: data)
            throw APIError.validationError(
                message: errorResponse?.message ?? "Validation failed",
                fields: errorResponse?.fields
            )

        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.message
            )
        }
    }

    // MARK: - Token Refresh

    private func refreshAccessToken() async throws -> String {
        guard let refreshToken = await tokenManager.getRefreshToken() else {
            throw APIError.noRefreshToken
        }

        struct RefreshRequest: Encodable {
            let refreshToken: String
        }

        struct RefreshResponse: Decodable {
            let accessToken: String
            let expiresIn: Int
        }

        var urlRequest = URLRequest(url: APIEndpoint.refreshToken.url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try encoder.encode(RefreshRequest(refreshToken: refreshToken))

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.tokenExpired
        }

        let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)
        await tokenManager.updateAccessToken(refreshResponse.accessToken)
        return refreshResponse.accessToken
    }
}
