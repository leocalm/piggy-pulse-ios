import Foundation

/// Configuration for E2E tests.
/// The API URL can be overridden via the E2E_API_URL environment variable
/// or launch argument. Defaults to the Docker Compose backend.
enum TestConfig {
    static let apiBaseURL: String = {
        if let envURL = ProcessInfo.processInfo.environment["E2E_API_URL"] {
            return envURL
        }
        return "http://127.0.0.1:18080/v2"
    }()

    static let defaultTimeout: TimeInterval = 10
    static let longTimeout: TimeInterval = 30

    static let testPassword = "E2E-TestPass-2026!Strong"
}
