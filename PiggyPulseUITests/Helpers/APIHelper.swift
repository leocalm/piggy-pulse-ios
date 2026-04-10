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

        XCTAssertNotNil(token, "Registration succeeded but no token returned")
        return TestUser(name: name, email: email, password: TestConfig.testPassword, token: token)
    }

    /// Set the user's currency via profile update (required before creating accounts).
    static func setProfile(token: String, currency: String = "EUR") {
        _ = syncRequest(
            method: "PUT",
            path: "/settings/profile",
            body: ["name": "E2E User", "currency": currency, "avatar": "🐷"],
            token: token
        )
    }

    /// Create a budget period for the current month.
    static func createPeriod(token: String) {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let startDate = String(format: "%04d-%02d-01", year, month)

        // End date: last day of month
        let range = calendar.range(of: .day, in: .month, for: now)!
        let endDate = String(format: "%04d-%02d-%02d", year, month, range.count)

        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let name = fmt.string(from: now)

        _ = syncRequest(
            method: "POST",
            path: "/periods",
            body: [
                "periodType": "ManualEndDate",
                "startDate": startDate,
                "name": name,
                "manualEndDate": endDate,
            ],
            token: token
        )
    }

    /// Complete onboarding for the user.
    static func completeOnboarding(token: String) {
        _ = syncRequest(method: "POST", path: "/onboarding/complete", token: token)
    }

    /// Seed: set profile (currency) and create a period for the current month.
    /// Onboarding completion is handled via the UI (skip flow).
    static func seedUserData(token: String) {
        setProfile(token: token)
        createPeriod(token: token)
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
        var responseStatus: Int?
        var responseError: Error?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            responseData = data
            responseStatus = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if let error = responseError {
            XCTFail("API request failed: \(method) \(path) — \(error.localizedDescription)")
        }

        if let status = responseStatus, status >= 400 {
            let body = responseData.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
            XCTFail("API \(method) \(path) returned \(status): \(body)")
        }

        return responseData
    }
}
