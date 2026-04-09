import XCTest

/// Page object for the Vendors screen.
struct VendorsPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.buttons["More"].tap()
        app.buttons["more-vendors"].waitForExistence()
        app.buttons["more-vendors"].tap()
    }

    func createVendor(name: String) {
        app.buttons["vendors-add-button"].waitForExistence()
        app.buttons["vendors-add-button"].tap()

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
