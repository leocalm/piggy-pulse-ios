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
        sleep(1) // Wait for sheet animation

        // The account type defaults to Checking. Only change if different.
        // Tapping the Picker opens a menu — select the desired type then dismiss.
        if type.lowercased() != "checking" {
            let typePicker = app.buttons["account-type-picker"]
            if typePicker.waitForExistence(timeout: 3) {
                typePicker.tap()
                // Select the desired type from the menu
                let option = app.buttons[type]
                if option.waitForExistence(timeout: 3) {
                    option.tap()
                }
            }
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

        // Dismiss keyboard (numeric keypad blocks the toolbar submit button)
        app.swipeDown()
        sleep(1)

        // Submit
        let submitButton = app.buttons["account-form-submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5), "account-form-submit not found")
        submitButton.tap()

        // Wait for sheet to close
        sleep(1)
    }

    func expectAccountVisible(name: String) {
        let account = app.staticTexts[name]
        XCTAssertTrue(account.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected account '\(name)' to be visible")
    }
}
