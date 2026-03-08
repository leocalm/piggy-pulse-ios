# Category Targets Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to set a budget target amount or mark a category as excluded from tracking, directly within the "Category targets" screen on iOS.

**Architecture:** Replace the read-only `BudgetPlanView` category list (currently using `/budget-categories/`) with a fully interactive list backed by the `/category-targets/` API. A new `EditCategoryTargetSheet` bottom sheet handles setting/clearing amounts and toggling exclusion. `BudgetViewModel` gains mutation methods alongside updated fetch logic.

**Tech Stack:** SwiftUI, async/await, `APIClient` (snake_case↔camelCase auto-conversion), `@MainActor` ObservableObject ViewModel, `@EnvironmentObject AppState`

---

### Task 1: Add `CategoryTarget` model

**Files:**
- Create: `Core/Models/CategoryTarget.swift`

**Step 1: Create the model**

```swift
import Foundation

struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let targetValue: Int32   // cents; 0 means "no target set"
    let excluded: Bool
}

struct CategoryTargetsResponse: Codable {
    let periodId: UUID
    let targets: [CategoryTarget]
}

struct BatchUpsertTargetsRequest: Encodable {
    struct TargetItem: Encodable {
        let categoryId: UUID
        let targetValue: Int32
    }
    let periodId: UUID
    let targets: [TargetItem]
}
```

**Step 2: Build the project to confirm it compiles**

In Xcode: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add Core/Models/CategoryTarget.swift
git commit -m "feat(budget): add CategoryTarget model and request/response types"
```

---

### Task 2: Add API endpoints for `/category-targets/`

**Files:**
- Modify: `Core/Network/APIEndpoints.swift`

**Step 1: Read the current file** (already done — the `// MARK: - Budget` section ends at line 161)

**Step 2: Add the new endpoints** after the existing Budget section:

```swift
// MARK: - Category Targets

extension APIEndpoint {
    static let categoryTargets = APIEndpoint(path: "/category-targets/", method: .get, requiresAuth: true)
    static let upsertCategoryTargets = APIEndpoint(path: "/category-targets/", method: .post, requiresAuth: true)
    static func excludeCategoryTarget(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/category-targets/\(id)/exclude", method: .post, requiresAuth: true)
    }
    static func includeCategoryTarget(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/category-targets/\(id)/include", method: .post, requiresAuth: true)
    }
}
```

**Step 3: Build to confirm it compiles**

Cmd+B → Build Succeeded

**Step 4: Commit**

```bash
git add Core/Network/APIEndpoints.swift
git commit -m "feat(budget): add category-targets API endpoints"
```

---

### Task 3: Update `BudgetViewModel` to load and mutate category targets

**Files:**
- Modify: `Features/Budget/ViewModels/BudgetViewModel.swift`

**Step 1: Replace the entire file content**

```swift
import SwiftUI
internal import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var burnIn: MonthlyBurnIn?
    @Published var targets: [CategoryTarget] = []
    @Published var allCategories: [CategoryListItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func load(periodId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let burnInTask: MonthlyBurnIn = apiClient.request(
                .monthlyBurnIn,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            async let targetsTask: CategoryTargetsResponse = apiClient.request(
                .categoryTargets,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            async let categoriesTask: PaginatedResponse<CategoryListItem> = apiClient.request(
                .categories,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )

            let (b, t, c) = try await (burnInTask, targetsTask, categoriesTask)
            burnIn = b
            targets = t.targets
            allCategories = c.data
        } catch {
            errorMessage = String(localized: "Failed to load budget data.")
        }

        isLoading = false
    }

    // MARK: - Mutations

    func setTarget(categoryId: UUID, value: Int32, periodId: UUID) async {
        isSaving = true
        let body = BatchUpsertTargetsRequest(
            periodId: periodId,
            targets: [.init(categoryId: categoryId, targetValue: value)]
        )
        do {
            try await apiClient.request(.upsertCategoryTargets, body: body)
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to save target.")
        }
        isSaving = false
    }

    func excludeTarget(id: UUID, periodId: UUID) async {
        isSaving = true
        do {
            try await apiClient.request(.excludeCategoryTarget(id))
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to exclude category.")
        }
        isSaving = false
    }

    func includeTarget(id: UUID, periodId: UUID) async {
        isSaving = true
        do {
            try await apiClient.request(.includeCategoryTarget(id))
            await load(periodId: periodId)
        } catch {
            errorMessage = String(localized: "Failed to re-include category.")
        }
        isSaving = false
    }

    // MARK: - Helpers

    /// Returns the CategoryListItem (for icon/color) matching a given CategoryTarget, if available.
    func categoryDetail(for target: CategoryTarget) -> CategoryListItem? {
        allCategories.first { $0.id == target.categoryId }
    }
}
```

**Step 2: Build to confirm it compiles**

Cmd+B → Build Succeeded (expect a warning that `categories` was removed — that's fine, the view will be updated next)

**Step 3: Commit**

```bash
git add Features/Budget/ViewModels/BudgetViewModel.swift
git commit -m "feat(budget): update BudgetViewModel to use category-targets API"
```

---

### Task 4: Create `EditCategoryTargetSheet`

**Files:**
- Create: `Features/Budget/Views/EditCategoryTargetSheet.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct EditCategoryTargetSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let target: CategoryTarget
    let detail: CategoryListItem?
    var onSave: (Int32) async -> Void
    var onExclude: () async -> Void
    var onInclude: () async -> Void

    @State private var amountText: String = ""
    @State private var isLoading = false

    private var parsedCents: Int32? {
        // Accept decimal input like "12.50" or "1250" and convert to cents
        guard let value = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return Int32(value * 100)
    }

    private var isSaveDisabled: Bool {
        parsedCents == nil || parsedCents! <= 0 || isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()
                VStack(spacing: PPSpacing.xl) {
                    // Header
                    HStack(spacing: PPSpacing.md) {
                        Text(detail?.icon ?? "📂")
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.categoryName)
                                .font(.ppTitle)
                                .foregroundColor(.ppTextPrimary)
                            if target.excluded {
                                Text("Currently excluded")
                                    .font(.ppCaption)
                                    .foregroundColor(.ppAmber)
                            }
                        }
                        Spacer()
                    }
                    .padding(PPSpacing.xl)
                    .background(Color.ppCard)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                    // Amount input
                    if !target.excluded {
                        VStack(alignment: .leading, spacing: PPSpacing.sm) {
                            Text("TARGET AMOUNT")
                                .font(.ppOverline)
                                .foregroundColor(.ppTextSecondary)
                                .tracking(1)

                            HStack {
                                Text(appState.currencyCode)
                                    .font(.ppCallout)
                                    .foregroundColor(.ppTextTertiary)
                                    .frame(width: 40)
                                TextField("0.00", text: $amountText)
                                    .font(.ppAmount)
                                    .foregroundColor(.ppTextPrimary)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(PPSpacing.lg)
                            .background(Color.ppSurface)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        }
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: PPSpacing.md) {
                        if !target.excluded {
                            Button {
                                guard let cents = parsedCents else { return }
                                Task {
                                    isLoading = true
                                    await onSave(cents)
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Save Target")
                                            .font(.ppHeadline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PPSpacing.lg)
                                .background(isSaveDisabled ? Color.ppPrimary.opacity(0.4) : Color.ppPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                            .disabled(isSaveDisabled)

                            Button {
                                Task {
                                    isLoading = true
                                    await onExclude()
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Text("Exclude from budget")
                                    .font(.ppCallout)
                                    .foregroundColor(.ppAmber)
                            }
                            .disabled(isLoading)
                        } else {
                            Button {
                                Task {
                                    isLoading = true
                                    await onInclude()
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Text("Re-include in budget")
                                    .font(.ppHeadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, PPSpacing.lg)
                                    .background(Color.ppCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                            .disabled(isLoading)
                        }
                    }
                }
                .padding(PPSpacing.xl)
            }
            .navigationTitle("Set Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
            }
            .onAppear {
                // Pre-fill if a target already exists
                if target.targetValue > 0 {
                    let amount = Double(target.targetValue) / 100.0
                    amountText = String(format: "%.2f", amount)
                }
            }
        }
    }
}
```

**Step 2: Build to confirm it compiles**

Cmd+B → Build Succeeded

**Step 3: Commit**

```bash
git add Features/Budget/Views/EditCategoryTargetSheet.swift
git commit -m "feat(budget): add EditCategoryTargetSheet for setting/excluding targets"
```

---

### Task 5: Rewrite `BudgetPlanView` to show all categories with target states

**Files:**
- Modify: `Features/Budget/Views/BudgetPlanView.swift`

**Step 1: Replace the entire file content**

```swift
import SwiftUI

struct BudgetPlanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: BudgetViewModel
    @State private var selectedTarget: CategoryTarget?

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: BudgetViewModel(apiClient: apiClient))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView().tint(.ppTextSecondary)
                        Spacer()
                    }
                    .padding(.vertical, PPSpacing.xxxl)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    VStack(spacing: PPSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.ppAmber)
                        Text(error)
                            .font(.ppBody)
                            .foregroundColor(.ppTextSecondary)
                        Button("Retry") {
                            if let periodId = appState.selectedPeriod?.id {
                                Task { await viewModel.load(periodId: periodId) }
                            }
                        }
                        .font(.ppHeadline)
                        .foregroundColor(.ppPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.xxxl)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                }
            } else {
                // Budget Summary card
                if let burnIn = viewModel.burnIn {
                    Section {
                        summaryCard(burnIn: burnIn)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                }

                // Category targets
                let withTarget = viewModel.targets.filter { !$0.excluded && $0.targetValue > 0 }
                let excluded = viewModel.targets.filter { $0.excluded }
                let noTarget = viewModel.targets.filter { !$0.excluded && $0.targetValue == 0 }

                if !withTarget.isEmpty {
                    Section {
                        ForEach(withTarget) { target in
                            targetRow(target)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        if let periodId = appState.selectedPeriod?.id {
                                            Task { await viewModel.excludeTarget(id: target.id, periodId: periodId) }
                                        }
                                    } label: {
                                        Label("Exclude", systemImage: "eye.slash")
                                    }
                                    .tint(.ppAmber)
                                }
                                .onTapGesture { selectedTarget = target }
                        }
                    } header: {
                        Text("WITH TARGET")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                    }
                }

                if !noTarget.isEmpty {
                    Section {
                        ForEach(noTarget) { target in
                            noTargetRow(target)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                .onTapGesture { selectedTarget = target }
                        }
                    } header: {
                        Text("NO TARGET")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                    }
                }

                if !excluded.isEmpty {
                    Section {
                        ForEach(excluded) { target in
                            excludedRow(target)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        if let periodId = appState.selectedPeriod?.id {
                                            Task { await viewModel.includeTarget(id: target.id, periodId: periodId) }
                                        }
                                    } label: {
                                        Label("Include", systemImage: "eye")
                                    }
                                    .tint(.ppCyan)
                                }
                                .onTapGesture { selectedTarget = target }
                        }
                    } header: {
                        Text("EXCLUDED")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                    }
                }

                if viewModel.targets.isEmpty {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 32))
                                .foregroundColor(.ppTextTertiary)
                            Text("No categories yet")
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Text("Create categories to set budget targets.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.ppBackground)
        .refreshable {
            if let periodId = appState.selectedPeriod?.id {
                await viewModel.load(periodId: periodId)
            }
        }
        .task(id: appState.selectedPeriod?.id) {
            if let periodId = appState.selectedPeriod?.id {
                await viewModel.load(periodId: periodId)
            }
        }
        .navigationTitle("Category targets")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTarget) { target in
            EditCategoryTargetSheet(
                target: target,
                detail: viewModel.categoryDetail(for: target),
                onSave: { cents in
                    if let periodId = appState.selectedPeriod?.id {
                        await viewModel.setTarget(categoryId: target.categoryId, value: cents, periodId: periodId)
                    }
                },
                onExclude: {
                    if let periodId = appState.selectedPeriod?.id {
                        await viewModel.excludeTarget(id: target.id, periodId: periodId)
                    }
                },
                onInclude: {
                    if let periodId = appState.selectedPeriod?.id {
                        await viewModel.includeTarget(id: target.id, periodId: periodId)
                    }
                }
            )
            .environmentObject(appState)
        }
    }

    // MARK: - Summary Card

    private func summaryCard(burnIn: MonthlyBurnIn) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("BUDGET BREAKDOWN")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            VStack(spacing: PPSpacing.md) {
                breakdownRow("Total Budget", value: burnIn.totalBudget, color: .ppPrimary)
                breakdownRow("Currently Spent", value: burnIn.spentBudget, color: .ppTextSecondary)
                breakdownRow("Remaining Budget", value: burnIn.remainingBudget, color: .ppCyan)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(burnIn.spentPercentage > 1.0 ? Color.ppDestructive : Color.ppPrimary)
                        .frame(width: geo.size.width * min(burnIn.spentPercentage, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func breakdownRow(_ label: LocalizedStringKey, value: Int64, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(formatCurrency(value, code: appState.currencyCode))
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
        }
    }

    // MARK: - Category Rows

    private func targetRow(_ target: CategoryTarget) -> some View {
        let detail = viewModel.categoryDetail(for: target)
        return HStack(spacing: PPSpacing.md) {
            Text(detail?.icon ?? "📂")
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(target.categoryName)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                Text(formatCurrency(Int64(target.targetValue), code: appState.currencyCode))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func noTargetRow(_ target: CategoryTarget) -> some View {
        let detail = viewModel.categoryDetail(for: target)
        return HStack(spacing: PPSpacing.md) {
            Text(detail?.icon ?? "📂")
                .font(.system(size: 20))
                .opacity(0.5)
            Text(target.categoryName)
                .font(.ppHeadline)
                .foregroundColor(.ppTextTertiary)
            Spacer()
            Text("No target")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
            Image(systemName: "plus.circle")
                .font(.ppCallout)
                .foregroundColor(.ppPrimary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder.opacity(0.5), lineWidth: 1))
    }

    private func excludedRow(_ target: CategoryTarget) -> some View {
        let detail = viewModel.categoryDetail(for: target)
        return HStack(spacing: PPSpacing.md) {
            Text(detail?.icon ?? "📂")
                .font(.system(size: 20))
                .grayscale(1)
                .opacity(0.4)
            Text(target.categoryName)
                .font(.ppHeadline)
                .foregroundColor(.ppTextTertiary)
                .strikethrough(true, color: .ppTextTertiary)
            Spacer()
            Text("Excluded")
                .font(.ppCaption)
                .foregroundColor(.ppAmber)
                .padding(.horizontal, PPSpacing.sm)
                .padding(.vertical, 2)
                .background(Color.ppAmber.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder.opacity(0.3), lineWidth: 1))
    }
}
```

**Step 2: Build to confirm it compiles**

Cmd+B → Build Succeeded

**Step 3: Smoke-test on simulator**

- Open the app and navigate to "Category targets"
- Confirm three sections appear (WITH TARGET, NO TARGET, EXCLUDED) based on data
- Tap a row → `EditCategoryTargetSheet` opens
- Enter an amount, tap "Save Target" → sheet dismisses and list refreshes
- Swipe left on a target row → "Exclude" button appears
- Swipe left on an excluded row → "Include" button appears

**Step 4: Commit**

```bash
git add Features/Budget/Views/BudgetPlanView.swift
git commit -m "feat(budget): rewrite BudgetPlanView with interactive category targets"
```

---

### Task 6: Check for compilation issues in the rest of the project

**Files:**
- Read: any file that previously used `BudgetViewModel.categories` or `BudgetCategoryItem`

**Step 1: Search for references**

```bash
grep -r "BudgetCategoryItem\|viewModel\.categories" --include="*.swift" .
```

Expected: zero hits (the model was only used inside `BudgetViewModel` and `BudgetPlanView`).
If hits are found, update those references to use `targets: [CategoryTarget]` instead.

**Step 2: Full build**

Cmd+B → Build Succeeded with no errors

**Step 3: Commit if any fixes were needed**

```bash
git add -p
git commit -m "fix(budget): update stale references after BudgetCategoryItem removal"
```

---

### Task 7: Push branch and open draft PR

**Step 1: Push**

```bash
git push -u origin HEAD
```

**Step 2: Open draft PR**

```bash
gh pr create --draft \
  --title "feat(budget): category targets — set amounts and exclude categories" \
  --body "$(cat <<'EOF'
## Summary
- Replaces read-only budget categories list with interactive category targets
- Users can tap any category to set a budget target amount or exclude it from tracking
- Swipe actions for quick exclude/include without opening the sheet
- Three visual sections: With Target, No Target, Excluded

## Test plan
- [ ] Navigate to Category Targets screen — all categories load with correct state
- [ ] Tap a category with no target → sheet opens, enter amount, Save → appears in With Target section
- [ ] Tap a category with an existing target → sheet pre-fills the amount
- [ ] Tap "Exclude from budget" → category moves to Excluded section
- [ ] Swipe left on a target row → Exclude swipe action visible and works
- [ ] Swipe left on an excluded row → Include swipe action visible and works
- [ ] Re-include an excluded category → moves back to correct section
- [ ] Pull-to-refresh reloads data correctly
- [ ] Switching budget periods reloads targets for the new period

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
