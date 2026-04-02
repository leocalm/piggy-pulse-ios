import SwiftUI
import TipKit
internal import Combine

final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var isComplete = false
    @Published var errorMessage: String?

    // MARK: - Step 1: Currency

    @Published var currencies: [Currency] = []
    @Published var selectedCurrencyId: UUID?
    @Published var currencySearch: String = ""

    var filteredCurrencies: [Currency] {
        let q = currencySearch.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return currencies }
        return currencies.filter {
            $0.name.lowercased().contains(q) ||
            $0.code.lowercased().contains(q) ||
            $0.symbol.lowercased().contains(q)
        }
    }

    var selectedCurrency: Currency? {
        currencies.first { $0.id == selectedCurrencyId }
    }

    // MARK: - Step 2: Periods (informational only — defaults used)
    // No editable state; defaults are always used on save.

    // MARK: - Step 3: Accounts

    @Published var accounts: [DraftAccount] = [DraftAccount()]

    // MARK: - Step 4: Categories (API templates)

    @Published var templates: [OnboardingTemplate] = []
    @Published var selectedTemplateId: String?
    @Published var appliedCategories: [OnboardingTemplateCategory] = []
    @Published var isLoadingTemplates = false

    var selectedTemplate: OnboardingTemplate? {
        templates.first { $0.id == selectedTemplateId }
    }

    // MARK: - Validation

    var canAdvance: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .currency:
            return selectedCurrencyId != nil
        case .period:
            return true
        case .accounts:
            // Skippable: valid if empty OR all entries are valid
            return accounts.isEmpty || accounts.allSatisfy(\.isValid)
        case .categories:
            return true
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

    // MARK: - Load on appear

    func loadStatus() async {
        isLoading = true
        defer { isLoading = false }

        // Always load currencies on init
        await loadCurrencies()

        do {
            let response: OnboardingStatusResponse = try await apiClient.request(.onboardingStatus)
            if let stepStr = response.currentStep,
               let step = OnboardingStep(rawValue: stepStr) {
                currentStep = step
                for s in OnboardingStep.allCases where s.index < step.index {
                    savedSteps.insert(s)
                }
                if step.index >= OnboardingStep.accounts.index {
                    await loadExistingAccounts()
                }
                if step.index >= OnboardingStep.categories.index {
                    await loadExistingCategories()
                }
            } else {
                currentStep = .welcome
            }
        } catch {
            currentStep = .welcome
        }
    }

    func loadCurrencies() async {
        guard currencies.isEmpty else { return }
        do {
            let list: [Currency] = try await apiClient.request(.currencies)
            await MainActor.run {
                currencies = list
                if selectedCurrencyId == nil {
                    selectedCurrencyId = currencies.first?.id
                }
            }
        } catch {
            // Non-fatal
        }
    }

    func loadTemplates() async {
        guard templates.isEmpty else { return }
        isLoadingTemplates = true
        defer { isLoadingTemplates = false }
        do {
            let list: [OnboardingTemplate] = try await apiClient.request(.onboardingTemplates)
            templates = list
        } catch {
            // Non-fatal — user can still skip
        }
    }

    private func loadExistingAccounts() async {
        do {
            struct ProfileResponse: Decodable { let currency: String }
            if let profile = try? await apiClient.request(.profile) as ProfileResponse,
               let match = currencies.first(where: { $0.code == profile.currency }) {
                selectedCurrencyId = match.id
            } else {
                selectedCurrencyId = currencies.first?.id
            }

            // AccountResponse uses Serde tagged enum: {"type": "Checking", "name": ..., "status": ...}
            // The "type" field acts as both the discriminator and the account type.
            struct AccountItem: Decodable {
                let name: String; let type: String
                let initialBalance: Int64; let spendLimit: Int64?
                let status: String
                enum CodingKeys: String, CodingKey { case name, type, initialBalance, spendLimit, status }
            }
            struct AccountListResponse: Decodable {
                let data: [AccountItem]
            }
            let response: AccountListResponse = try await apiClient.request(.accounts)
            let active = response.data.filter { $0.status.lowercased() == "active" }
            if !active.isEmpty {
                accounts = active.map { item in
                    var draft = DraftAccount()
                    draft.name = item.name
                    draft.accountType = item.type
                    draft.balanceText = String(format: "%.2f", Double(item.initialBalance) / 100)
                    if let limit = item.spendLimit, limit > 0 {
                        draft.spendLimitText = String(format: "%.2f", Double(limit) / 100)
                    }
                    return draft
                }
                savedSteps.insert(.accounts)
            }
        } catch { /* non-fatal — user can re-enter accounts */ }
    }

    private func loadExistingCategories() async {
        do {
            let response: CategoriesManagementResponse = try await apiClient.request(.categoriesManagement)
            let active = (response.incoming + response.outgoing).filter { !$0.isArchived }
            if !active.isEmpty {
                appliedCategories = active.map { item in
                    OnboardingTemplateCategory(
                        name: item.name,
                        icon: item.icon,
                        type: item.type,
                        behavior: item.behavior
                    )
                }
                savedSteps.insert(.categories)
            }
        } catch { /* non-fatal */ }
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
            case .welcome:
                break  // No save needed
            case .currency:
                if !savedSteps.contains(.currency) {
                    try await saveCurrency()
                    savedSteps.insert(.currency)
                }
            case .period:
                if !savedSteps.contains(.period) {
                    try await savePeriod()
                    savedSteps.insert(.period)
                }
            case .accounts:
                if !savedSteps.contains(.accounts) && !accounts.isEmpty {
                    try await saveAccounts()
                    savedSteps.insert(.accounts)
                }
            case .categories:
                if !savedSteps.contains(.categories), let templateId = selectedTemplateId {
                    try await applyTemplate(templateId)
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

    func skip() {
        errorMessage = nil
        let all = OnboardingStep.allCases
        if let idx = all.firstIndex(of: currentStep), idx + 1 < all.count {
            currentStep = all[idx + 1]
        }
    }

    // MARK: - Step saves

    private func saveCurrency() async throws {
        guard let currencyId = selectedCurrencyId,
              let currency = currencies.first(where: { $0.id == currencyId }) else { return }
        struct ProfileResponse: Decodable { let name: String; let currency: String; let avatar: String }
        struct ProfileRequest: Encodable {
            let name: String; let currency: String; let avatar: String
        }
        let current: ProfileResponse = try await apiClient.request(.profile)
        try await apiClient.request(.updateProfile, body: ProfileRequest(
            name: current.name,
            currency: currency.code,
            avatar: current.avatar
        ))
    }

    private func savePeriod() async throws {
        struct ScheduleConfig: Encodable {
            let scheduleType: String
            let recurrenceMethod: String
            let startDayOfTheMonth: Int
            let periodDuration: Int
            let durationUnit: String
            let saturdayPolicy: String
            let sundayPolicy: String
            let namePattern: String
            let generateAhead: Int
        }
        let schedule = ScheduleConfig(
            scheduleType: "automatic",
            recurrenceMethod: "dayOfMonth",
            startDayOfTheMonth: 1,
            periodDuration: 1,
            durationUnit: "months",
            saturdayPolicy: WeekendBehavior.keep.rawValue,
            sundayPolicy: WeekendBehavior.keep.rawValue,
            namePattern: "{MONTH} {YEAR}",
            generateAhead: 3
        )
        try await apiClient.request(.createSchedule, body: schedule)
    }

    private func saveAccounts() async throws {
        struct AccountRequest: Encodable {
            let name: String; let color: String
            let type: String; let initialBalance: Int64; let spendLimit: Int32?
            let currencyId: UUID
        }
        for account in accounts {
            let req = AccountRequest(
                name: account.name.trimmingCharacters(in: .whitespaces),
                color: "#007AFF",
                type: account.accountType,
                initialBalance: account.balanceInCents,
                spendLimit: account.spendLimitInCents,
                currencyId: selectedCurrencyId ?? UUID()
            )
            try await apiClient.request(.createAccount, body: req)
        }
    }

    private func applyTemplate(_ templateId: String) async throws {
        struct ApplyRequest: Encodable { let templateId: String }
        let cats: [AppliedCategory] = try await apiClient.request(.applyOnboardingTemplate, body: ApplyRequest(templateId: templateId))
        // Store the template categories for the summary
        if let template = selectedTemplate {
            appliedCategories = template.categories
        }
    }

    private struct AppliedCategory: Decodable { let id: UUID; let name: String }

    private func finish() async throws {
        struct Empty: Encodable {}
        try await apiClient.request(.completeOnboarding, body: Empty())
        // Reset TipKit so new users see all tips fresh
        try? Tips.resetDatastore()
        try? Tips.configure([.displayFrequency(.immediate)])
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isComplete = true
    }
}
