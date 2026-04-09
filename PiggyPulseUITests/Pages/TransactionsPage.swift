import XCTest

/// Page object for the Transactions screen.
struct TransactionsPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap() // Transactions tab
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

        // Select from picker: try buttons first (menu items), then staticTexts
        selectPickerOption(app: app, pickerID: "transaction-category-select", optionText: category)
        selectPickerOption(app: app, pickerID: "transaction-account-select", optionText: account)

        if isTransfer, let toAccount {
            selectPickerOption(app: app, pickerID: "transaction-to-account-select", optionText: toAccount)
        }

        // Submit
        app.buttons["transaction-form-submit"].tap()
        sleep(1)
    }

    /// Select an option from a Picker/Menu by tapping the picker, then finding the option.
    private func selectPickerOption(app: XCUIApplication, pickerID: String, optionText: String) {
        let picker = app.buttons[pickerID]
        guard picker.waitForExistence(timeout: 5) else {
            XCTFail("Picker '\(pickerID)' not found")
            return
        }
        picker.tap()
        sleep(1) // Wait for menu/picker to open

        let predicate = NSPredicate(format: "label CONTAINS %@", optionText)

        // Try buttons first (menu items in iOS)
        let menuButton = app.buttons.matching(predicate).firstMatch
        if menuButton.waitForExistence(timeout: 3) {
            menuButton.tap()
            return
        }

        // Try static texts
        let text = app.staticTexts.matching(predicate).firstMatch
        if text.waitForExistence(timeout: 3) {
            text.tap()
            return
        }

        // Try any element
        let any = app.descendants(matching: .any).matching(predicate).firstMatch
        if any.waitForExistence(timeout: 3) {
            any.tap()
            return
        }

        XCTFail("Option containing '\(optionText)' not found in picker '\(pickerID)'")
    }

    func expectTransactionVisible(description: String) {
        let transaction = app.staticTexts[description]
        XCTAssertTrue(transaction.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected transaction '\(description)' to be visible")
    }
}
