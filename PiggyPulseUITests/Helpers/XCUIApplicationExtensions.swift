import XCTest

extension XCUIApplication {
    /// Launch the app configured for E2E testing with the test API backend.
    func launchForE2E(apiURL: String = TestConfig.apiBaseURL) {
        launchArguments += ["-E2E_API_URL", apiURL]
        launchEnvironment["E2E_API_URL"] = apiURL
        launch()
    }
}

extension XCUIElement {
    /// Wait for the element to exist with a custom timeout, then return it.
    @discardableResult
    func waitForExistence(timeout: TimeInterval = TestConfig.defaultTimeout, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        let exists = self.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element \(self) did not appear within \(timeout)s", file: file, line: line)
        return self
    }

    /// Clear the text field and type new text.
    func clearAndType(_ text: String) {
        tap()
        // Select all and delete
        if let value = value as? String, !value.isEmpty {
            let selectAll = XCUIApplication().menuItems["Select All"]
            if selectAll.waitForExistence(timeout: 1) {
                selectAll.tap()
                typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }
        typeText(text)
    }
}
