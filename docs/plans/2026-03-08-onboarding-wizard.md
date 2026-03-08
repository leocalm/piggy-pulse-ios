# Onboarding Wizard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 4-step onboarding wizard (Period → Accounts → Categories → Summary) that new users complete before accessing the main app.

**Architecture:** Single `OnboardingViewModel` (`ObservableObject`) holds all wizard state and handles API calls. `OnboardingView` is a full-screen, non-dismissible container that shows the current step. `RootView` branches to `OnboardingView` when `currentUser.onboardingStatus != "completed"`. Step resume relies entirely on `GET /api/v1/onboarding/status` — the backend derives the current step from existing data.

**Tech Stack:** SwiftUI, async/await, existing `APIClient` + `APIEndpoint` pattern, existing design tokens (`PPSpacing`, `PPRadius`, `Color.ppXxx`, `Font.ppXxx`).

---

## Task 1: Add onboarding API endpoints

**Files:**
- Modify: `Core/Network/APIEndpoints.swift`

**Step 1: Add the two onboarding endpoints**

At the bottom of `APIEndpoints.swift`, add:

```swift
// MARK: - Onboarding

extension APIEndpoint {
    static let onboardingStatus = APIEndpoint(path: "/onboarding/status", method: .get, requiresAuth: true)
    static let completeOnboarding = APIEndpoint(path: "/onboarding/complete", method: .post, requiresAuth: true)
}
```

Also add the period schedule creation endpoint (used by onboarding step 1):

```swift
// Already exists: createSchedule — verify it maps to POST /budget_period/schedule ✓
```

**Step 2: Commit**

```bash
git add Core/Network/APIEndpoints.swift
git commit -m "feat(onboarding): add onboarding API endpoints"
```

---

## Task 2: Add onboarding models

**Files:**
- Create: `Core/Models/Onboarding.swift`

**Step 1: Create the file**

```swift
import Foundation

// MARK: - API response

struct OnboardingStatusResponse: Codable {
    let status: String           // "not_started" | "in_progress" | "completed"
    let currentStep: String?     // "period" | "accounts" | "categories" | "summary" | nil
}

// MARK: - Wizard step enum

enum OnboardingStep: String, CaseIterable {
    case period
    case accounts
    case categories
    case summary

    var title: String {
        switch self {
        case .period:     return "Periods"
        case .accounts:   return "Accounts"
        case .categories: return "Categories"
        case .summary:    return "Review"
        }
    }

    var index: Int {
        OnboardingStep.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Weekend behavior

enum WeekendBehavior: String, CaseIterable {
    case keep = "Keep"
    case shiftFriday = "ShiftFriday"
    case shiftMonday = "ShiftMonday"

    var label: String {
        switch self {
        case .keep:        return "Keep on weekend"
        case .shiftFriday: return "Shift to Friday"
        case .shiftMonday: return "Shift to Monday"
        }
    }
}

// MARK: - Draft models (local, pre-submission)

struct DraftAccount: Identifiable {
    let id = UUID()
    var name: String = ""
    var accountType: String = "Checking"
    var balanceText: String = ""
    var spendLimitText: String = ""

    var balanceInCents: Int64 {
        let cleaned = balanceText.replacingOccurrences(of: ",", with: ".")
        return Int64((Double(cleaned) ?? 0) * 100)
    }

    var spendLimitInCents: Int32? {
        guard accountType == "CreditCard" || accountType == "Allowance",
              !spendLimitText.isEmpty else { return nil }
        let cleaned = spendLimitText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned) else { return nil }
        return Int32(v * 100)
    }

    var showSpendLimit: Bool {
        accountType == "CreditCard" || accountType == "Allowance"
    }

    var defaultIcon: String {
        switch accountType {
        case "Checking":   return "🏦"
        case "Savings":    return "💰"
        case "CreditCard": return "💳"
        case "Wallet":     return "👛"
        case "Allowance":  return "🎯"
        default:           return "🏦"
        }
    }

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
    }
}

struct DraftCategory: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var categoryType: String   // "Incoming" | "Outgoing"
}

// MARK: - Category template

enum CategoryTemplate {
    case none, essential, detailed, custom

    var categories: [DraftCategory] {
        switch self {
        case .none, .custom:
            return []
        case .essential:
            return [
                DraftCategory(name: "Income",    icon: "💵", categoryType: "Incoming"),
                DraftCategory(name: "Housing",   icon: "🏠", categoryType: "Outgoing"),
                DraftCategory(name: "Food",      icon: "🍔", categoryType: "Outgoing"),
                DraftCategory(name: "Transport", icon: "🚗", categoryType: "Outgoing"),
                DraftCategory(name: "Other",     icon: "📦", categoryType: "Outgoing"),
            ]
        case .detailed:
            return [
                DraftCategory(name: "Salary",            icon: "💼", categoryType: "Incoming"),
                DraftCategory(name: "Freelance",         icon: "💻", categoryType: "Incoming"),
                DraftCategory(name: "Investment Income", icon: "📈", categoryType: "Incoming"),
                DraftCategory(name: "Rent / Mortgage",   icon: "🏠", categoryType: "Outgoing"),
                DraftCategory(name: "Utilities",         icon: "💡", categoryType: "Outgoing"),
                DraftCategory(name: "Groceries",         icon: "🛒", categoryType: "Outgoing"),
                DraftCategory(name: "Dining",            icon: "🍽️", categoryType: "Outgoing"),
                DraftCategory(name: "Transport",         icon: "🚗", categoryType: "Outgoing"),
                DraftCategory(name: "Health",            icon: "🏥", categoryType: "Outgoing"),
                DraftCategory(name: "Entertainment",     icon: "🎬", categoryType: "Outgoing"),
                DraftCategory(name: "Clothing",          icon: "👗", categoryType: "Outgoing"),
                DraftCategory(name: "Other",             icon: "📦", categoryType: "Outgoing"),
            ]
        }
    }
}

// MARK: - Currency (for accounts step)

struct Currency: Codable, Identifiable, Hashable {
    let id: UUID
    let code: String
    let name: String
    let symbol: String
}
```

**Step 2: Commit**

```bash
git add Core/Models/Onboarding.swift
git commit -m "feat(onboarding): add onboarding models and draft types"
```

---

## Task 3: Create OnboardingViewModel

**Files:**
- Create: `Features/Onboarding/OnboardingViewModel.swift`

**Step 1: Create the ViewModel**

```swift
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var currentStep: OnboardingStep = .period
    @Published var isLoading = true
    @Published var isSaving = false
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
            return true   // defaults always valid; custom fields are capped/bounded
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
            struct CurrencyListResponse: Codable {
                let currencies: [Currency]
            }
            let response: CurrencyListResponse = try await apiClient.request(.currencies)
            currencies = response.currencies
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
            // Move to next step
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
        struct ScheduleRequest: Encodable {
            let startDay: Int
            let durationValue: Int
            let durationUnit: String
            let saturdayAdjustment: String
            let sundayAdjustment: String
            let namePattern: String
            let generateAhead: Int
        }
        let req = ScheduleRequest(
            startDay: customize ? startDay : 1,
            durationValue: customize ? periodLength : 1,
            durationUnit: "months",
            saturdayAdjustment: customize ? saturdayBehavior.rawValue : WeekendBehavior.keep.rawValue,
            sundayAdjustment: customize ? sundayBehavior.rawValue : WeekendBehavior.keep.rawValue,
            namePattern: "MMMM yyyy",
            generateAhead: customize ? periodsToPrepare : 3
        )
        let _: PeriodSchedule = try await apiClient.request(.createSchedule, body: req)
    }

    private func saveAccounts() async throws {
        guard let currencyId = selectedCurrencyId else { return }

        // Save currency preference first
        struct PrefRequest: Encodable { let defaultCurrencyId: UUID }
        try await apiClient.request(.updatePreferences, body: PrefRequest(defaultCurrencyId: currencyId))

        // Create each account
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
```

**Step 2: Commit**

```bash
git add Features/Onboarding/OnboardingViewModel.swift
git commit -m "feat(onboarding): add OnboardingViewModel with step navigation and API calls"
```

---

## Task 4: Create shared NumberStepperView component

**Files:**
- Create: `Features/Onboarding/Components/NumberStepperView.swift`

This is a reusable stepper used in the Period step (start day, period length, periods to prepare).

**Step 1: Create the component**

```swift
import SwiftUI

struct NumberStepperView: View {
    let label: String
    let description: String
    @Binding var value: Int
    var min: Int = 1
    var max: Int = 28

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label)
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
            Text(description)
                .font(.ppCaption).foregroundColor(.ppTextSecondary)
            HStack {
                Button {
                    if value > min { value -= 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value <= min)
                .foregroundColor(value <= min ? .ppTextTertiary : .ppTextPrimary)

                Spacer()
                Text("\(value)")
                    .font(.ppTitle3).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    .frame(minWidth: 40, alignment: .center)
                Spacer()

                Button {
                    if value < max { value += 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value >= max)
                .foregroundColor(value >= max ? .ppTextTertiary : .ppTextPrimary)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Components/NumberStepperView.swift
git commit -m "feat(onboarding): add reusable NumberStepperView component"
```

---

## Task 5: Create step indicator component

**Files:**
- Create: `Features/Onboarding/Components/OnboardingStepIndicator.swift`

A horizontal scrollable row of step chips. Active step is highlighted in `.ppPrimary`, completed steps are subdued.

**Step 1: Create the component**

```swift
import SwiftUI

struct OnboardingStepIndicator: View {
    let currentStep: OnboardingStep

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PPSpacing.sm) {
                ForEach(Array(OnboardingStep.allCases.enumerated()), id: \.element) { idx, step in
                    let isCurrent = step == currentStep
                    let isPast = step.index < currentStep.index

                    HStack(spacing: PPSpacing.xs) {
                        if isPast {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption).foregroundColor(.ppSuccess)
                        } else {
                            Text("\(idx + 1)")
                                .font(.ppCaption).fontWeight(.semibold)
                                .foregroundColor(isCurrent ? .ppPrimary : .ppTextTertiary)
                        }
                        Text(step.title)
                            .font(.ppCaption).fontWeight(isCurrent ? .semibold : .regular)
                            .foregroundColor(isCurrent ? .ppTextPrimary : .ppTextTertiary)
                    }
                    .padding(.horizontal, PPSpacing.md)
                    .padding(.vertical, PPSpacing.sm)
                    .background(isCurrent ? Color.ppPrimary.opacity(0.15) : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isCurrent ? Color.ppPrimary : Color.ppBorder, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, PPSpacing.xl)
        }
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Components/OnboardingStepIndicator.swift
git commit -m "feat(onboarding): add step indicator chip row component"
```

---

## Task 6: Create PeriodStepView

**Files:**
- Create: `Features/Onboarding/Steps/PeriodStepView.swift`

**Step 1: Create the view**

```swift
import SwiftUI

struct PeriodStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let saturdayOptions = WeekendBehavior.allCases
    private let sundayOptions   = WeekendBehavior.allCases

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Description
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Periods are how PiggyPulse slices your timeline for tracking. The default — monthly, starting on the 1st — works for most people.")
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    Text("You can further customize periods later in the Periods screen, including renaming them or adjusting individual start dates.")
                        .font(.ppCallout).foregroundColor(.ppTextSecondary)
                }

                // Customize toggle
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Configuration")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    Picker("", selection: $vm.customize) {
                        Text("Use default").tag(false)
                        Text("Customize").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                // Custom fields
                if vm.customize {
                    VStack(spacing: PPSpacing.md) {
                        NumberStepperView(
                            label: "Start Day",
                            description: "The day of the month your period begins. Capped at 28 so it exists every month.",
                            value: $vm.startDay
                        )
                        NumberStepperView(
                            label: "Period Length",
                            description: "How many months each period spans. Most people use 1.",
                            value: $vm.periodLength
                        )
                        NumberStepperView(
                            label: "Periods to Prepare",
                            description: "How many future periods to create in advance.",
                            value: $vm.periodsToPrepare
                        )

                        // Weekend adjustments
                        VStack(alignment: .leading, spacing: PPSpacing.md) {
                            Text("Weekend Days")
                                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("If the period start date falls on a weekend, PiggyPulse can shift it to the nearest weekday. This only affects when a period is recorded as starting — it does not change how long the period lasts.")
                                .font(.ppCaption).foregroundColor(.ppTextSecondary)

                            HStack {
                                Text("If it lands on Saturday")
                                    .font(.ppCallout).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Saturday", selection: $vm.saturdayBehavior) {
                                    ForEach(saturdayOptions, id: \.self) { opt in
                                        Text(opt.label).tag(opt)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }

                            HStack {
                                Text("If it lands on Sunday")
                                    .font(.ppCallout).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Sunday", selection: $vm.sundayBehavior) {
                                    ForEach(sundayOptions, id: \.self) { opt in
                                        Text(opt.label).tag(opt)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }
                        }
                        .padding(PPSpacing.lg)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: vm.customize)
                }
            }
            .padding(PPSpacing.xl)
        }
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Steps/PeriodStepView.swift
git commit -m "feat(onboarding): add PeriodStepView"
```

---

## Task 7: Create AccountsStepView

**Files:**
- Create: `Features/Onboarding/Steps/AccountsStepView.swift`

**Step 1: Create the view**

```swift
import SwiftUI

struct AccountsStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let accountTypes = ["Checking", "Savings", "CreditCard", "Wallet", "Allowance"]
    private let typeLabels = ["Checking": "Checking", "Savings": "Savings",
                               "CreditCard": "Credit Card", "Wallet": "Wallet", "Allowance": "Allowance"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("Accounts are where your money goes.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

                // Currency picker
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Currency")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    if vm.currencies.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Picker("Currency", selection: $vm.selectedCurrencyId) {
                            ForEach(vm.currencies) { currency in
                                Text("\(currency.symbol) \(currency.code) — \(currency.name)")
                                    .tag(Optional(currency.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.ppPrimary)
                        .padding(PPSpacing.md)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    }
                }

                // Account cards
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Accounts")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    ForEach($vm.accounts) { $account in
                        AccountCardView(account: $account, typeLabels: typeLabels, accountTypes: accountTypes, onRemove: {
                            vm.accounts.removeAll { $0.id == account.id }
                        })
                    }

                    if vm.accounts.count < 10 {
                        Button {
                            vm.accounts.append(DraftAccount())
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundColor(.ppPrimary)
                                Text("Add Account").font(.ppCallout).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(PPSpacing.md)
                            .background(Color.ppPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        }
                    }
                }
            }
            .padding(PPSpacing.xl)
        }
        .task { await vm.loadCurrencies() }
    }
}

// MARK: - Account card

private struct AccountCardView: View {
    @Binding var account: DraftAccount
    let typeLabels: [String: String]
    let accountTypes: [String]
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            HStack {
                Text(account.defaultIcon).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.isEmpty ? "New Account" : account.name)
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text(typeLabels[account.accountType] ?? account.accountType)
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                }
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.ppTextTertiary)
                }
            }

            Divider()

            // Name
            TextField("Account name", text: $account.name)
                .font(.ppBody).foregroundColor(.ppTextPrimary)
                .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))

            // Type
            HStack {
                Text("Type").font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                Picker("Type", selection: $account.accountType) {
                    ForEach(accountTypes, id: \.self) { t in
                        Text(typeLabels[t] ?? t).tag(t)
                    }
                }
                .pickerStyle(.menu).tint(.ppPrimary)
            }

            // Balance
            HStack {
                Text("Starting Balance").font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                TextField("0.00", text: $account.balanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .frame(width: 120)
            }

            // Spend limit
            if account.showSpendLimit {
                HStack {
                    Text("Spend Limit").font(.ppCallout).foregroundColor(.ppTextSecondary)
                    Text("(optional)").font(.ppCaption).foregroundColor(.ppTextTertiary)
                    Spacer()
                    TextField("0.00", text: $account.spendLimitText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .frame(width: 120)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: account.showSpendLimit)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Steps/AccountsStepView.swift
git commit -m "feat(onboarding): add AccountsStepView with currency picker and account cards"
```

---

## Task 8: Create CategoriesStepView

**Files:**
- Create: `Features/Onboarding/Steps/CategoriesStepView.swift`

**Step 1: Create the view**

```swift
import SwiftUI

struct CategoriesStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var showAddCategory = false
    @State private var newName = ""
    @State private var newIcon = "📦"
    @State private var newType = "Outgoing"

    private let templates: [(title: String, subtitle: String, template: CategoryTemplate)] = [
        ("Essential 5",  "5 basic categories to get started",        .essential),
        ("Detailed 12",  "12 categories for detailed tracking",       .detailed),
        ("Custom",       "Start with an empty list",                  .custom),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("Categories are how you organize your spendings.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

                // Template selector
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Choose a starting point")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    ForEach(templates, id: \.title) { item in
                        let isSelected = templateMatches(item.template)
                        Button { vm.applyTemplate(item.template) } label: {
                            HStack(spacing: PPSpacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.ppCallout).fontWeight(.semibold)
                                        .foregroundColor(isSelected ? .ppPrimary : .ppTextPrimary)
                                    Text(item.subtitle).font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.ppPrimary)
                                }
                            }
                            .padding(PPSpacing.lg)
                            .background(isSelected ? Color.ppPrimary.opacity(0.08) : Color.ppCard)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md)
                                .stroke(isSelected ? Color.ppPrimary : Color.ppBorder, lineWidth: isSelected ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Category list
                if !vm.categories.isEmpty || vm.selectedTemplate != .none {
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        let incoming = vm.categories.filter { $0.categoryType == "Incoming" }
                        let outgoing = vm.categories.filter { $0.categoryType == "Outgoing" }

                        if !incoming.isEmpty {
                            Text("Incoming").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppSuccess)
                            ForEach(incoming) { cat in
                                categoryRow(cat)
                            }
                        }
                        if !outgoing.isEmpty {
                            Text("Outgoing").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppDestructive)
                                .padding(.top, PPSpacing.sm)
                            ForEach(outgoing) { cat in
                                categoryRow(cat)
                            }
                        }
                    }
                }

                // Add category
                if vm.selectedTemplate != .none {
                    if showAddCategory {
                        addCategoryForm
                    } else {
                        Button {
                            showAddCategory = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundColor(.ppPrimary)
                                Text("Add Category").font(.ppCallout).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(PPSpacing.md)
                            .background(Color.ppPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        }
                    }
                }
            }
            .padding(PPSpacing.xl)
        }
    }

    private func categoryRow(_ cat: DraftCategory) -> some View {
        HStack {
            Text(cat.icon).font(.title3)
            Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary)
            Spacer()
            Button(role: .destructive) {
                vm.categories.removeAll { $0.id == cat.id }
            } label: {
                Image(systemName: "xmark").font(.caption).foregroundColor(.ppTextTertiary)
            }
        }
        .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
    }

    private var addCategoryForm: some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text("New Category").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)

            HStack(spacing: PPSpacing.sm) {
                TextField("Icon", text: $newIcon).frame(width: 48)
                    .font(.title3).multilineTextAlignment(.center)
                    .padding(.horizontal, PPSpacing.sm).padding(.vertical, PPSpacing.sm)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))

                TextField("Category name", text: $newName)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))
            }

            Picker("Direction", selection: $newType) {
                Text("Incoming").tag("Incoming")
                Text("Outgoing").tag("Outgoing")
            }.pickerStyle(.segmented)

            HStack {
                Button("Cancel") {
                    showAddCategory = false; newName = ""; newIcon = "📦"; newType = "Outgoing"
                }.foregroundColor(.ppTextSecondary)
                Spacer()
                Button("Add") {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    vm.addCategory(DraftCategory(name: newName.trimmingCharacters(in: .whitespaces), icon: newIcon, categoryType: newType))
                    showAddCategory = false; newName = ""; newIcon = "📦"; newType = "Outgoing"
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .foregroundColor(.ppPrimary).fontWeight(.semibold)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func templateMatches(_ template: CategoryTemplate) -> Bool {
        switch (vm.selectedTemplate, template) {
        case (.essential, .essential), (.detailed, .detailed), (.custom, .custom): return true
        default: return false
        }
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Steps/CategoriesStepView.swift
git commit -m "feat(onboarding): add CategoriesStepView with template selection and custom categories"
```

---

## Task 9: Create SummaryStepView

**Files:**
- Create: `Features/Onboarding/Steps/SummaryStepView.swift`

**Step 1: Create the view**

```swift
import SwiftUI

struct SummaryStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("You're all set — here's what will be configured when you enter PiggyPulse.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

                // Period summary
                summarySection(title: "Period") {
                    if vm.customize {
                        labeledRow("Start Day", "\(vm.startDay)")
                        labeledRow("Period Length", "\(vm.periodLength) month\(vm.periodLength == 1 ? "" : "s")")
                        labeledRow("Periods to Prepare", "\(vm.periodsToPrepare)")
                        labeledRow("If Saturday", vm.saturdayBehavior.label)
                        labeledRow("If Sunday", vm.sundayBehavior.label)
                    } else {
                        Text("Monthly, starting on the 1st (default)")
                            .font(.ppCallout).foregroundColor(.ppTextSecondary)
                    }
                }

                // Accounts summary
                summarySection(title: "Accounts") {
                    if let currencyId = vm.selectedCurrencyId,
                       let currency = vm.currencies.first(where: { $0.id == currencyId }) {
                        labeledRow("Currency", "\(currency.symbol) \(currency.code)")
                    }
                    ForEach(vm.accounts) { account in
                        HStack {
                            Text(account.defaultIcon)
                            Text(account.name.isEmpty ? "Unnamed" : account.name)
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                            Spacer()
                            Text(account.balanceText.isEmpty ? "0.00" : account.balanceText)
                                .font(.ppCallout).foregroundColor(.ppTextSecondary)
                        }
                    }
                }

                // Categories summary
                let incoming = vm.categories.filter { $0.categoryType == "Incoming" }
                let outgoing = vm.categories.filter { $0.categoryType == "Outgoing" }
                summarySection(title: "Categories") {
                    if !incoming.isEmpty {
                        Text("Incoming").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppSuccess)
                        ForEach(incoming) { cat in
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary) }
                        }
                    }
                    if !outgoing.isEmpty {
                        Text("Outgoing").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppDestructive)
                            .padding(.top, 4)
                        ForEach(outgoing) { cat in
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary) }
                        }
                    }
                }
            }
            .padding(PPSpacing.xl)
        }
    }

    @ViewBuilder
    private func summarySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text(title).font(.ppTitle3).foregroundColor(.ppTextPrimary)
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                content()
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value).font(.ppCallout).foregroundColor(.ppTextPrimary)
        }
    }
}
```

**Step 2: Commit**

```bash
git add Features/Onboarding/Steps/SummaryStepView.swift
git commit -m "feat(onboarding): add SummaryStepView"
```

---

## Task 10: Create OnboardingView container

**Files:**
- Create: `Features/Onboarding/OnboardingView.swift`

**Step 1: Create the container**

```swift
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: OnboardingViewModel

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(apiClient: appState.apiClient))
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: PPSpacing.md) {
                        Text("Welcome to PiggyPulse")
                            .font(.ppTitle2).fontWeight(.bold).foregroundColor(.ppTextPrimary)
                        OnboardingStepIndicator(currentStep: vm.currentStep)
                    }
                    .padding(.top, PPSpacing.xl)
                    .padding(.bottom, PPSpacing.md)

                    // Step content
                    Group {
                        switch vm.currentStep {
                        case .period:     PeriodStepView(vm: vm)
                        case .accounts:   AccountsStepView(vm: vm)
                        case .categories: CategoriesStepView(vm: vm)
                        case .summary:    SummaryStepView(vm: vm)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.ppCallout).foregroundColor(.ppDestructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PPSpacing.xl)
                    }

                    // Navigation buttons
                    HStack(spacing: PPSpacing.md) {
                        if vm.currentStep != .period {
                            Button("Back") { vm.goBack() }
                                .font(.ppCallout).foregroundColor(.ppTextSecondary)
                                .frame(minWidth: 80)
                        }
                        Spacer()
                        Button {
                            Task {
                                await vm.advance()
                                // After finishing, refresh user so RootView reacts
                                if vm.currentStep == .summary {
                                    // advance() only returns after completeOnboarding succeeds or throws
                                    // Re-fetch the user to update onboardingStatus
                                    await appState.checkAuth()
                                }
                            }
                        } label: {
                            if vm.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text(vm.currentStep == .summary ? "Finish" : "Continue")
                                    .font(.ppCallout).fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.vertical, PPSpacing.md)
                        .background(vm.canAdvance ? Color.ppPrimary : Color.ppPrimary.opacity(0.4))
                        .clipShape(Capsule())
                        .disabled(!vm.canAdvance || vm.isSaving)
                    }
                    .padding(.horizontal, PPSpacing.xl)
                    .padding(.vertical, PPSpacing.lg)
                }
            }
        }
        .task { await vm.loadStatus() }
        .interactiveDismissDisabled(true)
    }
}
```

> **Note on Finish:** After `vm.advance()` completes successfully on the `.summary` step, the ViewModel has called `completeOnboarding`. Then `appState.checkAuth()` re-fetches `/users/me`, which returns `onboardingStatus: "completed"`, causing `RootView` to switch to `MainTabView`.

**Step 2: Commit**

```bash
git add Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): add OnboardingView container with step routing and navigation"
```

---

## Task 11: Wire OnboardingView into RootView

**Files:**
- Modify: `App/Features/Navigation/RootView.swift`

**Step 1: Add the onboarding branch**

Replace the `isAuthenticated` branch with:

```swift
} else if appState.isAuthenticated {
    if appState.currentUser?.onboardingStatus == "completed" {
        MainTabView()
    } else {
        OnboardingView(appState: appState)
    }
}
```

Full updated file:

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ppBackground)
            } else if appState.isAuthenticated {
                if appState.currentUser?.onboardingStatus == "completed" {
                    MainTabView()
                } else {
                    OnboardingView(appState: appState)
                }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add App/Features/Navigation/RootView.swift
git commit -m "feat(onboarding): wire OnboardingView into RootView for new users"
```

---

## Task 12: Handle finish correctly in OnboardingView

**Note:** The `advance()` in the ViewModel doesn't know when to refresh the parent AppState. The cleanest approach is to have `OnboardingView` observe ViewModel state and call `appState.checkAuth()` reactively.

**Files:**
- Modify: `Features/Onboarding/OnboardingViewModel.swift`
- Modify: `Features/Onboarding/OnboardingView.swift`

**Step 1: Add a published flag to ViewModel**

In `OnboardingViewModel`, add:
```swift
@Published var isComplete = false
```

At the end of `finish()`, after the API call succeeds:
```swift
isComplete = true
```

**Step 2: React to completion in OnboardingView**

In `OnboardingView`, add a `.onChange` modifier:
```swift
.onChange(of: vm.isComplete) { _, complete in
    if complete {
        Task { await appState.checkAuth() }
    }
}
```

Remove the manual `appState.checkAuth()` call from inside the Button action.

**Step 3: Commit**

```bash
git add Features/Onboarding/OnboardingViewModel.swift Features/Onboarding/OnboardingView.swift
git commit -m "fix(onboarding): reactively refresh auth after onboarding completion"
```

---

## Task 13: Manual smoke test

**Step 1: Start the API**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-api
docker-compose up -d
```

**Step 2: Run the iOS app**

Open Xcode, select a simulator, and run. Log in with a new account (or reset onboarding status in DB).

**Step 3: Verify the flow**

- [ ] New user lands on OnboardingView (not MainTabView)
- [ ] Step indicator shows "Periods" highlighted
- [ ] Default (no customize) → Continue → moves to Accounts step
- [ ] Customize toggle reveals NumberSteppers and weekend pickers
- [ ] Accounts: currency loads, can add/remove accounts, Continue disabled until currency + valid account name
- [ ] Categories: selecting Essential 5 populates list; can add custom category; Continue disabled until ≥1 incoming + ≥1 outgoing
- [ ] Summary: shows all configured data correctly
- [ ] Finish → calls complete → RootView switches to MainTabView
- [ ] Kill and relaunch app mid-wizard → resumes at correct step

**Step 4: Create PR**

```bash
git push origin feat/onboarding-wizard
gh pr create --draft --title "feat(onboarding): add 4-step onboarding wizard" \
  --body "## Summary
- 4-step wizard: Period → Accounts → Categories → Summary
- Non-dismissible full-screen flow for new users
- Step resume via GET /api/v1/onboarding/status
- RootView branches on onboardingStatus

## Test plan
- [ ] New user sees wizard, not main app
- [ ] All 4 steps validate correctly before advancing
- [ ] Finish transitions to MainTabView
- [ ] App resume lands on correct step"
```
