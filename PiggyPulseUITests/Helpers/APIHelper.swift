import Foundation
import XCTest

/// Direct API calls for test setup (register users, seed data).
/// Uses URLSession synchronously to avoid XCUITest async complications.
enum APIHelper {
    struct TestUser {
        let name: String
        let email: String
        let password: String
        let token: String?
    }

    /// Register a unique test user via the API. Returns the user credentials and auth token.
    static func registerUser(name: String = "E2E User") -> TestUser {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 100_000...999_999)
        let email = "e2e-\(timestamp)-\(random)@test.piggypulse.com"

        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": TestConfig.testPassword,
        ]

        let result = syncRequest(
            method: "POST",
            path: "/auth/register",
            body: body
        )

        var token: String?
        if let data = result,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            token = json["token"] as? String
        }

        return TestUser(name: name, email: email, password: TestConfig.testPassword, token: token)
    }

    /// Make a synchronous API request. Returns the response data or nil.
    static func syncRequest(
        method: String,
        path: String,
        body: [String: Any]? = nil,
        token: String? = nil
    ) -> Data? {
        guard let url = URL(string: "\(TestConfig.apiBaseURL)\(path)") else {
            XCTFail("Invalid URL: \(TestConfig.apiBaseURL)\(path)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var responseError: Error?

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            responseData = data
            responseError = error
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if let error = responseError {
            XCTFail("API request failed: \(method) \(path) — \(error.localizedDescription)")
        }

        return responseData
    }
}
