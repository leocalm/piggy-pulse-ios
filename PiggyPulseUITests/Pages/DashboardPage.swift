import XCTest

/// Page object for the Dashboard screen.
struct DashboardPage {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.buttons["Dashboard"].tap()
    }

    func expectLoaded() {
        // Wait for any dashboard widget to appear
        let currentPeriod = app.otherElements["dashboard-current-period"]
        XCTAssertTrue(currentPeriod.waitForExistence(timeout: TestConfig.longTimeout),
                      "Expected dashboard to load with current period widget")
    }

    func getSpentText() -> String? {
        let spentLabel = app.staticTexts["dashboard-spent-value"]
        if spentLabel.waitForExistence(timeout: TestConfig.defaultTimeout) {
            return spentLabel.label
        }
        return nil
    }

    func getNetPositionText() -> String? {
        let netLabel = app.staticTexts["dashboard-net-position-value"]
        if netLabel.waitForExistence(timeout: TestConfig.defaultTimeout) {
            return netLabel.label
        }
        return nil
    }
}
