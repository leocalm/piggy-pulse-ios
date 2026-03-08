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
            return categories.contains(where: { $0.categoryType == "Incoming" })
                && categories.contains(where: { $0.categoryType == "Outgoing" })
        case .summary:
            return true
        }
    }

    // MARK: - Init

    private let apiClient: APIClient
    /// Steps that have already been saved to the server; skipped on re-advance.
    private var savedSteps: Set<OnboardingStep> = []

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
                // Mark all steps before the current one as already saved so we
                // don't re-POST data that the server already has.
                for s in OnboardingStep.allCases where s.index < step.index {
                    savedSteps.insert(s)
                }
                // Load existing data for steps already completed so the UI
                // reflects what's on the server and Back/Continue works cleanly.
                if step.index >= OnboardingStep.accounts.index {
                    await loadExistingAccounts()
                }
                if step.index >= OnboardingStep.categories.index {
                    await loadExistingCategories()
                }
            } else {
                currentStep = .period
            }
        } catch {
            currentStep = .period
        }
    }

    private func loadExistingAccounts() async {
        do {
            // Load currencies first so selectedCurrencyId can be restored
            if currencies.isEmpty {
                let currencyList: [Currency] = try await apiClient.request(.currencies)
                currencies = currencyList
            }
            // Restore selected currency from profile
            struct ProfileResponse: Decodable { let defaultCurrencyId: UUID? }
            if let profile = try? await apiClient.request(.profile) as ProfileResponse,
               let currencyId = profile.defaultCurrencyId {
                selectedCurrencyId = currencyId
            } else {
                selectedCurrencyId = currencies.first?.id
            }

            // /accounts/management returns a plain array with no period_id required
            struct AccountMgmt: Decodable {
                let name: String; let accountType: String
                let balance: Int64; let spendLimit: Int32?; let isArchived: Bool
            }
            let list: [AccountMgmt] = try await apiClient.request(.accountsManagement)
            let active = list.filter { !$0.isArchived }
            if !active.isEmpty {
                accounts = active.map { item in
                    var draft = DraftAccount()
                    draft.name = item.name
                    draft.accountType = item.accountType
                    draft.balanceText = String(format: "%.2f", Double(item.balance) / 100)
                    if let limit = item.spendLimit {
                        draft.spendLimitText = String(format: "%.2f", Double(limit) / 100)
                    }
                    return draft
                }
                savedSteps.insert(.accounts)
            }
        } catch {
            errorMessage = "Could not load existing accounts: \(error)"
        }
    }

    private func loadExistingCategories() async {
        do {
            // /categories/management returns grouped arrays with no period_id required
            let response: CategoriesManagementResponse = try await apiClient.request(.categoriesManagement)
            let active = (response.incoming + response.outgoing).filter { !$0.isArchived && !$0.isSystem }
            if !active.isEmpty {
                categories = active.map { item in
                    DraftCategory(name: item.name, icon: item.icon, categoryType: item.categoryType)
                }
                selectedTemplate = .custom
                savedSteps.insert(.categories)
            }
        } catch { /* non-fatal */ }
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
                try await savePeriod()     // PUT — always safe to re-send
            case .accounts:
                if !savedSteps.contains(.accounts) {
                    try await saveAccounts()
                    savedSteps.insert(.accounts)
                }
            case .categories:
                if !savedSteps.contains(.categories) {
                    try await saveCategories()
                    savedSteps.insert(.categories)
                }
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
            namePattern: "{MONTH} {YEAR}",
            generateAhead: customize ? periodsToPrepare : 3
        )
        try await apiClient.request(.updatePeriodModel, body: PeriodModelRequest(mode: "automatic", schedule: schedule))
    }

    private func saveAccounts() async throws {
        // Set default currency before creating accounts (required by backend).
        // Must include name + timezone since PUT /settings/profile requires them.
        if let currencyId = selectedCurrencyId {
            struct ProfileResponse: Decodable { let name: String; let timezone: String }
            struct ProfileRequest: Encodable {
                let name: String; let timezone: String; let defaultCurrencyId: UUID
            }
            let current: ProfileResponse = try await apiClient.request(.profile)
            try await apiClient.request(.updateProfile, body: ProfileRequest(
                name: current.name,
                timezone: current.timezone,
                defaultCurrencyId: currencyId
            ))
        }

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
