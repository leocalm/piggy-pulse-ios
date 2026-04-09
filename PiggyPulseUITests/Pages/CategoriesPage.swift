import XCTest

/// Page object for the Categories screen.
struct CategoriesPage {
    let app: XCUIApplication

    func navigateTo() {
        // Categories is in the More tab
        app.tabBars.buttons["More"].tap()
        app.buttons["more-categories"].waitForExistence()
        app.buttons["more-categories"].tap()
    }

    func createCategory(name: String, type: String) {
        app.buttons["categories-add-button"].waitForExistence()
        app.buttons["categories-add-button"].tap()

        // Select type (income/expense)
        let typeButton = app.buttons["category-type-\(type.lowercased())"]
        if typeButton.waitForExistence(timeout: 3) {
            typeButton.tap()
        }

        // Fill name
        let nameField = app.textFields["category-name-input"]
        nameField.waitForExistence()
        nameField.tap()
        nameField.typeText(name)

        // Submit
        app.buttons["category-form-submit"].tap()
        sleep(1)
    }

    func expectCategoryVisible(name: String) {
        let category = app.staticTexts[name]
        XCTAssertTrue(category.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected category '\(name)' to be visible")
    }
}
