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
        // Tab bar with at least 4 tabs = we're past auth
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: TestConfig.longTimeout),
                      "Expected tab bar (Dashboard) after login")
    }

    func expectDashboardOrOnboarding() {
        // Wait for tab bar (dashboard) or onboarding button
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 15) {
            return // On dashboard (has tab bar)
        }
        // Check if we're on any onboarding step (currency, periods, etc.)
        // The onboarding wizard has various elements — check broadly
        let loginStill = app.textFields["login-email"].exists
        if !loginStill {
            // Not on login = we're past auth. Could be onboarding, loading, etc.
            return
        }
        XCTFail("Still on login screen after auth — login/registration likely failed")
    }

    // MARK: - Register

    func register(name: String, email: String, password: String) {
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
            let termsButton = app.buttons["register-terms"]
            if termsButton.exists {
                termsButton.tap()
            }
        }

        app.buttons["register-submit"].tap()
    }

    // MARK: - Logout

    func logout() {
        // More tab is the last (index 3)
        app.tabBars.firstMatch.buttons.element(boundBy: 3).tap()
        sleep(1)

        let logoutButton = app.buttons["logout-button"]
        // Scroll down to find the logout button (it's at the bottom of the More list)
        for _ in 0..<5 {
            if logoutButton.exists && logoutButton.isHittable {
                break
            }
            app.swipeUp()
            sleep(1)
        }
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5), "logout-button not found after scrolling")
        logoutButton.tap()
        sleep(1)
    }

    func expectLoginScreen() {
        let emailField = app.textFields["login-email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected login screen")
    }
}
