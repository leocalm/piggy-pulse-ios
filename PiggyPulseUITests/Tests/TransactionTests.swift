import XCTest

/// Tests 8-10: Transactions — create expense, income, transfer
final class TransactionTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchForE2E()

        // Register + login + skip onboarding
        let user = APIHelper.registerUser(name: "Transaction Test")
        let auth = AuthPage(app: app)
        auth.login(email: user.email, password: user.password)
        auth.expectDashboardOrOnboarding()

        // Skip onboarding if shown
        if !app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            let onboarding = OnboardingPage(app: app)
            onboarding.skipToEnd()
            onboarding.expectDashboard()
        }

        // Seed: create account + categories
        let accounts = AccountsPage(app: app)
        accounts.navigateTo()
        accounts.createAccount(name: "Checking", type: "Checking", balance: "5000")

        let categories = CategoriesPage(app: app)
        categories.navigateTo()
        categories.createCategory(name: "Food", type: "expense")
        categories.createCategory(name: "Salary", type: "income")
    }

    /// Test 8: Create expense transaction appears in the list
    func testCreateExpenseTransaction() {
        let transactions = TransactionsPage(app: app)
        transactions.navigateTo()
        transactions.createTransaction(
            amount: "42.50",
            description: "Lunch",
            category: "Food",
            account: "Checking"
        )
        transactions.expectTransactionVisible(description: "Lunch")
    }

    /// Test 9: Create income transaction appears in the list
    func testCreateIncomeTransaction() {
        let transactions = TransactionsPage(app: app)
        transactions.navigateTo()
        transactions.createTransaction(
            amount: "2500",
            description: "Monthly salary",
            category: "Salary",
            account: "Checking"
        )
        transactions.expectTransactionVisible(description: "Monthly salary")
    }

    /// Test 10: Create transfer transaction appears in the list
    func testCreateTransferTransaction() {
        // Create a second account for the transfer
        let accounts = AccountsPage(app: app)
        accounts.navigateTo()
        accounts.createAccount(name: "Savings", type: "Savings", balance: "0")

        let transactions = TransactionsPage(app: app)
        transactions.navigateTo()
        transactions.createTransaction(
            amount: "500",
            description: "Move to savings",
            category: "Transfer",
            account: "Checking",
            isTransfer: true,
            toAccount: "Savings"
        )
        transactions.expectTransactionVisible(description: "Move to savings")
    }
}
