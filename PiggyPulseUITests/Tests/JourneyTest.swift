import XCTest

/// Test 11: Full first-time user journey
/// Register → Login → Accounts → Categories → Vendors → Transactions → Dashboard → Logout → Re-login
final class JourneyTest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// TODO: Logout button scroll needs more attempts on slow CI runners
    func testFirstTimeUserJourney() {
        // Register and seed via API
        let user = APIHelper.registerUser(name: "Journey User")
        guard let token = user.token else {
            XCTFail("Registration failed — no token")
            return
        }
        APIHelper.seedUserData(token: token)

        // Launch app and login
        app.launchForE2E()
        let auth = AuthPage(app: app)
        auth.login(email: user.email, password: user.password)
        auth.expectDashboardOrOnboarding()

        // Skip onboarding if shown
        if !app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            let onboarding = OnboardingPage(app: app)
            onboarding.skipToEnd()
            onboarding.expectDashboard()
        }

        let accounts = AccountsPage(app: app)
        let categories = CategoriesPage(app: app)
        let vendors = VendorsPage(app: app)
        let transactions = TransactionsPage(app: app)
        let dashboard = DashboardPage(app: app)

        // ── Step 1: Create accounts ──
        accounts.navigateTo()
        accounts.createAccount(name: "Checking", type: "Checking", balance: "2000")
        accounts.createAccount(name: "Savings", type: "Checking", balance: "5000")
        accounts.expectAccountVisible(name: "Checking")

        // ── Step 2: Create categories ──
        categories.navigateTo()
        categories.createCategory(name: "Groceries", type: "expense")
        categories.createCategory(name: "Salary", type: "income")

        // ── Step 3: Create vendor ──
        vendors.navigateTo()
        vendors.createVendor(name: "Albert Heijn")
        vendors.expectVendorVisible(name: "Albert Heijn")

        // ── Step 4: Create transactions ──
        transactions.navigateTo()
        transactions.createTransaction(
            amount: "3000",
            description: "April Salary",
            category: "Salary",
            account: "Checking"
        )

        transactions.navigateTo()
        transactions.createTransaction(
            amount: "85.50",
            description: "Weekly groceries",
            category: "Groceries",
            account: "Checking"
        )

        // ── Step 5: Verify dashboard loads ──
        dashboard.navigateTo()
        dashboard.expectLoaded()

        // ── Step 6: Logout ──
        auth.logout()
        auth.expectLoginScreen()

        // ── Step 7: Re-login ──
        auth.login(email: user.email, password: user.password)
        auth.expectDashboardOrOnboarding()
    }
}
