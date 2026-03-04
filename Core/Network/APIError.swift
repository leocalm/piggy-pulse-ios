import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case twoFactorRequired(token: String)
    case forbidden
    case notFound
    case validationError(message: String, fields: [String: String]?)
    case serverError(statusCode: Int, message: String?)
    case networkError(Error)
    case decodingError(Error)
    case tokenExpired
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to continue."
        case .twoFactorRequired:
            return "Two-factor authentication required."
        case .forbidden:
            return "You don't have permission to do that."
        case .notFound:
            return "The requested resource was not found."
        case .validationError(let message, _):
            return message
        case .serverError(_, let message):
            return message ?? "Something went wrong. Please try again."
        case .networkError:
            return "Unable to connect. Check your internet connection."
        case .decodingError:
            return "Received an unexpected response."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .noRefreshToken:
            return "Please sign in to continue."
        }
    }
}

// MARK: - Server Error Response Models

struct APIErrorResponse: Decodable {
    let error: String?
    let message: String?
    let twoFactorToken: String?
}

struct ValidationErrorResponse: Decodable {
    let message: String
    let fields: [String: String]?
}
