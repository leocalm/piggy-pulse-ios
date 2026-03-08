import SwiftUI
internal import Combine

final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var currentStep: OnboardingStep = .period
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var isComplete = false
    @Published var errorMessage: String?

    // MARK: - Step 1: Period

    @Published var customize = false
    @Published var startDay = 1
    @Published var periodLength = 1
    @Published var periodsToPrepare = 3
    @Published var saturdayBehavior: WeekendBehavior = .keep
    @Published var sundayBehavior: WeekendBehavior = .keep

    // MARK: - Step 2: Accounts

    @Published var currencies: [Currency] = []
    @Published var selectedCurrencyId: UUID?
    @Published var accounts: [DraftAccount] = [DraftAccount()]

    // MARK: - Step 3: Categories

    @Published var selectedTemplate: CategoryTemplate = .none
    @Published var categories: [DraftCategory] = []

    // MARK: - Validation

    var canAdvance: Bool {
        switch currentStep {
        case .period:
            return true
        case .accounts:
            return selectedCurrencyId != nil
                && !accounts.isEmpty
                && accounts.allSatisfy(\.isValid)
        case .categories:
            return selectedTemplate != .none
                && categories.contains(where: { $0.categoryType == "Incoming" })
                && categories.contains(where: { $0.categoryType == "Outgoing" })
        case .summary:
            return true
        }
    }

    // MARK: - Init

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load status on appear

    func loadStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: OnboardingStatusResponse = try await apiClient.request(.onboardingStatus)
            if let stepStr = response.currentStep,
               let step = OnboardingStep(rawValue: stepStr) {
                currentStep = step
            } else {
                currentStep = .period
            }
        } catch {
            currentStep = .period
        }
    }

    // MARK: - Load currencies (called by AccountsStep on appear)

    func loadCurrencies() async {
        guard currencies.isEmpty else { return }
        do {
            let list: [Currency] = try await apiClient.request(.currencies)
            currencies = list
            if selectedCurrencyId == nil {
                selectedCurrencyId = currencies.first?.id
            }
        } catch {
            // Non-fatal: user can retry by going back/forward
        }
    }

    // MARK: - Navigation

    func goBack() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep), idx > 0 else { return }
        currentStep = OnboardingStep.allCases[idx - 1]
        errorMessage = nil
    }

    func advance() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            switch currentStep {
            case .period:
                try await savePeriod()
            case .accounts:
                try await saveAccounts()
            case .categories:
                try await saveCategories()
            case .summary:
                try await finish()
                return
            }
            let all = OnboardingStep.allCases
            if let idx = all.firstIndex(of: currentStep), idx + 1 < all.count {
                currentStep = all[idx + 1]
            }
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = "Something went wrong. Please try again."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    // MARK: - Step saves

    private func savePeriod() async throws {
        struct ScheduleConfig: Encodable {
            let startDay: Int
            let durationValue: Int
            let durationUnit: String
            let saturdayAdjustment: String
            let sundayAdjustment: String
            let namePattern: String
            let generateAhead: Int
        }
        struct PeriodModelRequest: Encodable {
            let mode: String
            let schedule: ScheduleConfig
        }
        let schedule = ScheduleConfig(
            startDay: customize ? startDay : 1,
            durationValue: customize ? periodLength : 1,
            durationUnit: "months",
            saturdayAdjustment: customize ? saturdayBehavior.rawValue : WeekendBehavior.keep.rawValue,
            sundayAdjustment: customize ? sundayBehavior.rawValue : WeekendBehavior.keep.rawValue,
            namePattern: "MMMM yyyy",
            generateAhead: customize ? periodsToPrepare : 3
        )
        try await apiClient.request(.updatePeriodModel, body: PeriodModelRequest(mode: "automatic", schedule: schedule))
    }

    private func saveAccounts() async throws {
        guard let currencyId = selectedCurrencyId else { return }

        struct PrefRequest: Encodable { let defaultCurrencyId: UUID }
        try await apiClient.request(.updatePreferences, body: PrefRequest(defaultCurrencyId: currencyId))

        struct AccountRequest: Encodable {
            let name: String; let color: String; let icon: String
            let accountType: String; let balance: Int64; let spendLimit: Int32?
        }
        for account in accounts {
            let req = AccountRequest(
                name: account.name.trimmingCharacters(in: .whitespaces),
                color: "#007AFF",
                icon: account.defaultIcon,
                accountType: account.accountType,
                balance: account.balanceInCents,
                spendLimit: account.spendLimitInCents
            )
            try await apiClient.request(.createAccount, body: req)
        }
    }

    private func saveCategories() async throws {
        struct CategoryRequest: Encodable {
            let name: String; let icon: String
            let color: String; let categoryType: String
        }
        for category in categories {
            let req = CategoryRequest(
                name: category.name,
                icon: category.icon,
                color: "#228be6",
                categoryType: category.categoryType
            )
            try await apiClient.request(.createCategory, body: req)
        }
    }

    private func finish() async throws {
        struct Empty: Encodable {}
        try await apiClient.request(.completeOnboarding, body: Empty())
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isComplete = true
    }

    // MARK: - Category helpers

    func applyTemplate(_ template: CategoryTemplate) {
        selectedTemplate = template
        categories = template.categories
    }

    func addCategory(_ category: DraftCategory) {
        categories.append(category)
    }

    func removeCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
}
