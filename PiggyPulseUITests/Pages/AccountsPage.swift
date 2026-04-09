import XCTest

/// Page object for the Accounts screen.
struct AccountsPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap() // Accounts tab
    }

    func createAccount(name: String, type: String, balance: String) {
        let addButton = app.buttons["accounts-add-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: TestConfig.longTimeout),
                      "accounts-add-button not found — page may show NoPeriodState")
        addButton.tap()

        // Select account type
        let typeButton = app.buttons["account-type-\(type.lowercased())"]
        if typeButton.waitForExistence(timeout: 3) {
            typeButton.tap()
        }

        // Fill name
        let nameField = app.textFields["account-name-input"]
        nameField.waitForExistence()
        nameField.tap()
        nameField.typeText(name)

        // Fill balance
        let balanceField = app.textFields["account-balance-input"]
        balanceField.tap()
        balanceField.typeText(balance)

        // Submit
        app.buttons["account-form-submit"].tap()

        // Wait for sheet to close
        sleep(1)
    }

    func expectAccountVisible(name: String) {
        let account = app.staticTexts[name]
        XCTAssertTrue(account.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected account '\(name)' to be visible")
    }
}
