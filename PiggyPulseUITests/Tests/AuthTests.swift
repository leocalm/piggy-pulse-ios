import XCTest

/// Tests 1-3: Authentication — login, wrong password, registration
final class AuthTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchForE2E()
    }

    /// Test 1: Login with valid credentials redirects to dashboard or onboarding
    /// TODO: Timing-sensitive on CI — needs longer timeouts for slow runners
    func testLoginWithValidCredentials() {
        let user = APIHelper.registerUser(name: "Login Test")
        let auth = AuthPage(app: app)

        auth.login(email: user.email, password: user.password)
        auth.expectDashboardOrOnboarding()
    }

    /// Test 2: Login with wrong password shows error
    func testLoginWithWrongPassword() {
        let user = APIHelper.registerUser(name: "Wrong PW Test")
        let auth = AuthPage(app: app)

        auth.login(email: user.email, password: "WrongPassword!123")

        // Should stay on login screen with an error
        let errorAlert = app.staticTexts["login-error"]
            .firstMatch
        let errorExists = errorAlert.waitForExistence(timeout: TestConfig.defaultTimeout)
        // Either an error message or still on login page
        if !errorExists {
            auth.expectLoginScreen()
        }
    }

    /// Test 3: Registration with valid credentials redirects to onboarding
    /// TODO: Timing-sensitive on CI — needs longer timeouts for slow runners
    func testRegistration() {
        let auth = AuthPage(app: app)
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let email = "e2e-register-\(timestamp)@test.piggypulse.com"

        auth.register(
            name: "Registration Test",
            email: email,
            password: TestConfig.testPassword
        )

        auth.expectDashboardOrOnboarding()
    }
}
