import XCTest

/// Page object for the Transactions screen.
struct TransactionsPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.buttons["Transactions"].tap()
    }

    func createTransaction(
        amount: String,
        description: String,
        category: String,
        account: String,
        date: String? = nil,
        isTransfer: Bool = false,
        toAccount: String? = nil,
        vendor: String? = nil
    ) {
        app.buttons["transactions-add-button"].waitForExistence()
        app.buttons["transactions-add-button"].tap()

        // Toggle transfer mode if needed
        if isTransfer {
            let toggle = app.switches["transaction-transfer-toggle"]
            if toggle.waitForExistence(timeout: 2) {
                toggle.tap()
            }
        }

        // Fill amount
        let amountField = app.textFields["transaction-amount-input"]
        amountField.waitForExistence()
        amountField.tap()
        amountField.typeText(amount)

        // Fill description
        let descField = app.textFields["transaction-description-input"]
        descField.tap()
        descField.typeText(description)

        // Select category
        let categoryPicker = app.buttons["transaction-category-select"]
        if categoryPicker.waitForExistence(timeout: 3) {
            categoryPicker.tap()
            app.staticTexts[category].waitForExistence()
            app.staticTexts[category].tap()
        }

        // Select account
        let accountPicker = app.buttons["transaction-account-select"]
        if accountPicker.waitForExistence(timeout: 3) {
            accountPicker.tap()
            app.staticTexts[account].waitForExistence()
            app.staticTexts[account].tap()
        }

        // Select to-account for transfers
        if isTransfer, let toAccount {
            let toAccountPicker = app.buttons["transaction-to-account-select"]
            if toAccountPicker.waitForExistence(timeout: 3) {
                toAccountPicker.tap()
                app.staticTexts[toAccount].waitForExistence()
                app.staticTexts[toAccount].tap()
            }
        }

        // Submit
        app.buttons["transaction-form-submit"].tap()
        sleep(1)
    }

    func expectTransactionVisible(description: String) {
        let transaction = app.staticTexts[description]
        XCTAssertTrue(transaction.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected transaction '\(description)' to be visible")
    }
}
