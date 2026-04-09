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
                      "Expected Dashboard tab after login")
    }

    func expectDashboardOrOnboarding() {
        // Simple approach: wait and check what appeared
        sleep(3)
        let onDashboard = app.tabBars.buttons["Dashboard"].exists
        let onOnboarding = app.otherElements["onboarding-wizard"].exists
            || app.buttons["onboarding-next"].exists
            || app.staticTexts["onboarding-title"].exists
        XCTAssertTrue(onDashboard || onOnboarding,
                      "Expected Dashboard or Onboarding after auth, but found neither")
    }

    // MARK: - Register

    func register(name: String, email: String, password: String) {
        // Navigate to register screen
        let signUpLink = app.buttons["register-link"]
        if signUpLink.waitForExistence(timeout: 5) {
            signUpLink.tap()
        }

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
        let termsToggle = app.switches["register-terms"]
        if termsToggle.exists {
            termsToggle.tap()
        } else {
            // Try as button (checkbox-style)
            let termsButton = app.buttons["register-terms"]
            if termsButton.exists {
                termsButton.tap()
            }
        }

        app.buttons["register-submit"].tap()
    }

    // MARK: - Logout

    func logout() {
        // Navigate to More tab → Logout
        app.tabBars.buttons["More"].tap()
        sleep(1)

        // Scroll down to find logout button if needed
        let logoutButton = app.buttons["logout-button"]
        if !logoutButton.exists {
            app.swipeUp()
        }
        logoutButton.waitForExistence()
        logoutButton.tap()

        // Confirm logout if dialog appears
        sleep(1)
        let confirmSheet = app.buttons["Logout"]
        if confirmSheet.exists {
            confirmSheet.tap()
        }
    }

    func expectLoginScreen() {
        let emailField = app.textFields["login-email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected login screen")
    }
}
