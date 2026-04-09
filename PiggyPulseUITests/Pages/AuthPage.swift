import XCTest

/// Page object for authentication screens (Login, Register).
struct AuthPage {
    let app: XCUIApplication

    // MARK: - Login

    func login(email: String, password: String) {
        let emailField = app.textFields["login-email"]
        emailField.waitForExistence()
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["login-password"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["login-submit"].tap()
    }

    func expectDashboard() {
        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: TestConfig.longTimeout),
                      "Expected to land on Dashboard after login")
    }

    func expectOnboarding() {
        let onboarding = app.staticTexts["onboarding-title"]
        XCTAssertTrue(onboarding.waitForExistence(timeout: TestConfig.longTimeout),
                      "Expected onboarding screen")
    }

    func expectDashboardOrOnboarding() {
        // Wait for either Dashboard tab or onboarding title
        let dashboard = app.tabBars.buttons["Dashboard"]
        let onboarding = app.otherElements["onboarding-wizard"]
        let predicate = NSPredicate(format: "exists == true")
        let expectations = [
            XCTNSPredicateExpectation(predicate: predicate, object: dashboard),
            XCTNSPredicateExpectation(predicate: predicate, object: onboarding),
        ]
        // Wait for any one
        let result = XCTWaiter().wait(for: expectations, timeout: TestConfig.longTimeout)
        XCTAssertTrue(result == .completed || result == .invertedFulfillment,
                      "Expected Dashboard or Onboarding after auth")
    }

    // MARK: - Register

    func register(name: String, email: String, password: String) {
        app.buttons["register-link"].tap()

        let nameField = app.textFields["register-name"]
        nameField.waitForExistence()
        nameField.tap()
        nameField.typeText(name)

        let emailField = app.textFields["register-email"]
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["register-password"]
        passwordField.tap()
        passwordField.typeText(password)

        let confirmField = app.secureTextFields["register-confirm-password"]
        confirmField.tap()
        confirmField.typeText(password)

        // Accept terms
        app.switches["register-terms"].tap()

        app.buttons["register-submit"].tap()
    }

    // MARK: - Logout

    func logout() {
        // Navigate to More tab → Logout
        app.tabBars.buttons["More"].tap()
        let logoutButton = app.buttons["logout-button"]
        logoutButton.waitForExistence()
        logoutButton.tap()

        // Confirm logout if dialog appears
        let confirmButton = app.buttons["Logout"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }
    }

    func expectLoginScreen() {
        let emailField = app.textFields["login-email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected login screen")
    }
}
