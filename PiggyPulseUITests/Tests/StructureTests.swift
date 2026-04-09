import XCTest

/// Tests 4-7: Structure — accounts, categories, vendors
final class StructureTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchForE2E()

        // Register + login + skip onboarding
        let user = APIHelper.registerUser(name: "Structure Test")
        let auth = AuthPage(app: app)
        auth.login(email: user.email, password: user.password)
        auth.expectDashboardOrOnboarding()

        // Skip onboarding if shown
        if !app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            let onboarding = OnboardingPage(app: app)
            onboarding.skipToEnd()
            onboarding.expectDashboard()
        }
    }

    /// Test 4: Create account appears in the accounts list
    func testCreateAccount() {
        let accounts = AccountsPage(app: app)
        accounts.navigateTo()
        accounts.createAccount(name: "Checking", type: "Checking", balance: "2000")
        accounts.expectAccountVisible(name: "Checking")
    }

    /// Test 5: Create expense category appears in the categories list
    func testCreateExpenseCategory() {
        let categories = CategoriesPage(app: app)
        categories.navigateTo()
        categories.createCategory(name: "Groceries", type: "expense")
        categories.expectCategoryVisible(name: "Groceries")
    }

    /// Test 6: Create income category appears in the categories list
    func testCreateIncomeCategory() {
        let categories = CategoriesPage(app: app)
        categories.navigateTo()
        categories.createCategory(name: "Salary", type: "income")
        categories.expectCategoryVisible(name: "Salary")
    }

    /// Test 7: Create vendor appears in the vendors list
    func testCreateVendor() {
        let vendors = VendorsPage(app: app)
        vendors.navigateTo()
        vendors.createVendor(name: "Albert Heijn")
        vendors.expectVendorVisible(name: "Albert Heijn")
    }
}
