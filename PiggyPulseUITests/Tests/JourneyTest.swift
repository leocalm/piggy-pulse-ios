import XCTest

/// Test 11: Full first-time user journey
/// Register → Onboarding → Accounts → Categories → Vendors → Transactions → Dashboard → Logout → Re-login
final class JourneyTest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchForE2E()
    }

    func testFirstTimeUserJourney() {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let email = "e2e-journey-\(timestamp)@test.piggypulse.com"
        let password = TestConfig.testPassword

        let auth = AuthPage(app: app)
        let onboarding = OnboardingPage(app: app)
        let accounts = AccountsPage(app: app)
        let categories = CategoriesPage(app: app)
        let vendors = VendorsPage(app: app)
        let transactions = TransactionsPage(app: app)
        let dashboard = DashboardPage(app: app)

        // ── Step 1: Register ──
        auth.register(name: "Journey User", email: email, password: password)
        auth.expectDashboardOrOnboarding()

        // ── Step 2: Skip onboarding ──
        if !app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5) {
            onboarding.skipToEnd()
        }
        onboarding.expectDashboard()

        // ── Step 3: Create accounts ──
        accounts.navigateTo()
        accounts.createAccount(name: "Checking", type: "Checking", balance: "2000")
        accounts.createAccount(name: "Savings", type: "Savings", balance: "5000")

        // ── Step 4: Verify accounts exist ──
        accounts.expectAccountVisible(name: "Checking")
        accounts.expectAccountVisible(name: "Savings")

        // ── Step 5: Create categories ──
        categories.navigateTo()
        categories.createCategory(name: "Groceries", type: "expense")
        categories.createCategory(name: "Rent", type: "expense")
        categories.createCategory(name: "Salary", type: "income")

        // ── Step 6: Create vendor ──
        vendors.navigateTo()
        vendors.createVendor(name: "Albert Heijn")
        vendors.expectVendorVisible(name: "Albert Heijn")

        // ── Step 7: Create transactions ──
        transactions.navigateTo()
        transactions.createTransaction(
            amount: "3000",
            description: "April Salary",
            category: "Salary",
            account: "Checking"
        )

        transactions.navigateTo()
        transactions.createTransaction(
            amount: "1200",
            description: "April Rent",
            category: "Rent",
            account: "Checking"
        )

        transactions.navigateTo()
        transactions.createTransaction(
            amount: "85.50",
            description: "Weekly groceries",
            category: "Groceries",
            account: "Checking",
            vendor: "Albert Heijn"
        )

        // ── Step 8: Verify dashboard loads ──
        dashboard.navigateTo()
        dashboard.expectLoaded()

        // ── Step 9: Logout ──
        auth.logout()
        auth.expectLoginScreen()

        // ── Step 10: Re-login ──
        auth.login(email: email, password: password)
        auth.expectDashboardOrOnboarding()

        // ── Step 11: Verify dashboard still works ──
        if app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5) {
            dashboard.navigateTo()
            dashboard.expectLoaded()
        }
    }
}
