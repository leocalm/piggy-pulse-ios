import XCTest

/// Page object for the onboarding wizard.
struct OnboardingPage {
    let app: XCUIApplication

    /// Skip through all onboarding steps to reach the dashboard.
    func skipToEnd() {
        for _ in 0..<10 {
            // Check if we're already past onboarding
            if app.tabBars.firstMatch.exists {
                return
            }

            // Currency step: select Euro if visible
            let eurOption = app.buttons["currency-EUR"]
            if eurOption.exists {
                eurOption.tap()
                sleep(1)
            }

            // Try go-to-dashboard first, then skip, then next
            let goToDashboard = app.buttons["onboarding-go-to-dashboard"]
            if goToDashboard.waitForExistence(timeout: 1) {
                goToDashboard.tap()
                sleep(1)
                return
            }

            let skip = app.buttons["onboarding-skip"]
            if skip.waitForExistence(timeout: 1) {
                skip.tap()
                sleep(1)
                continue
            }

            let next = app.buttons["onboarding-next"]
            if next.waitForExistence(timeout: 2) {
                next.tap()
                sleep(1)
                continue
            }

            break
        }
    }

    func expectDashboard() {
        let dashboard = app.tabBars.firstMatch
        XCTAssertTrue(dashboard.waitForExistence(timeout: TestConfig.longTimeout),
                      "Expected Dashboard after onboarding")
    }
}
