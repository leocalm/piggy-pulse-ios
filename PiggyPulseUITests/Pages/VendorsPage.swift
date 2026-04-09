import XCTest

/// Page object for the Vendors screen.
struct VendorsPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.firstMatch.buttons.element(boundBy: 3).tap() // More tab
        app.buttons["more-vendors"].waitForExistence()
        app.buttons["more-vendors"].tap()
    }

    func createVendor(name: String) {
        let addButton = app.buttons["vendors-add-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: TestConfig.longTimeout),
                      "vendors-add-button not found")
        addButton.tap()

        let nameField = app.textFields["vendor-name-input"]
        nameField.waitForExistence()
        nameField.tap()
        nameField.typeText(name)

        app.buttons["vendor-form-submit"].tap()
        sleep(1)
    }

    func expectVendorVisible(name: String) {
        let vendor = app.staticTexts[name]
        XCTAssertTrue(vendor.waitForExistence(timeout: TestConfig.defaultTimeout),
                      "Expected vendor '\(name)' to be visible")
    }
}
