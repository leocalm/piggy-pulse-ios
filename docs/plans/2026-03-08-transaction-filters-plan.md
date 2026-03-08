# Transaction Filters Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add server-side account/category/vendor multi-select filters to the Transactions list, surfaced via a HIG-compliant filter sheet.

**Architecture:** Filter state (`Set<UUID>` × 3) lives in `TransactionsViewModel`. The filter sheet fetches options lazily from existing options APIs on first open. Selected IDs are passed as repeated query params to `TransactionRepository`, which forwards them to the backend.

**Tech Stack:** SwiftUI, async/await, existing `APIClient`, existing options endpoints (`/accounts/options`, `/categories/options`, `/vendors`).

---

### Task 1: Extend `TransactionRepository` to accept filter IDs

**Files:**
- Modify: `Core/Repositories/TransactionRepository.swift`

**Step 1: Add filter params to `fetchTransactions`**

Replace the existing signature and query-building block:

```swift
func fetchTransactions(
    periodId: UUID,
    direction: TransactionDirection = .all,
    cursor: UUID? = nil,
    limit: Int = 20,
    accountIds: [UUID] = [],
    categoryIds: [UUID] = [],
    vendorIds: [UUID] = []
) async throws -> CursorPaginatedTransactions {
    var queryItems = [
        URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased()),
        URLQueryItem(name: "limit", value: String(limit))
    ]

    if let dirValue = direction.queryValue {
        queryItems.append(URLQueryItem(name: "direction", value: dirValue))
    }

    if let cursor = cursor {
        queryItems.append(URLQueryItem(name: "cursor", value: cursor.uuidString.lowercased()))
    }

    for id in accountIds {
        queryItems.append(URLQueryItem(name: "account_id", value: id.uuidString.lowercased()))
    }
    for id in categoryIds {
        queryItems.append(URLQueryItem(name: "category_id", value: id.uuidString.lowercased()))
    }
    for id in vendorIds {
        queryItems.append(URLQueryItem(name: "vendor_id", value: id.uuidString.lowercased()))
    }

    return try await apiClient.request(.transactions, queryItems: queryItems)
}
```

**Step 2: Build and verify no compiler errors**

```bash
xcodebuild -scheme piggy-pulse-ios -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 3: Commit**

```bash
git add Core/Repositories/TransactionRepository.swift
git commit -m "feat(filters): extend TransactionRepository with account/category/vendor filter params"
```

---

### Task 2: Add filter state and options loading to `TransactionsViewModel`

**Files:**
- Modify: `Features/Transactions/ViewModels/TransactionsViewModel.swift`
- Reference: `Core/Models/FormOptions.swift` — `AccountOption`, `CategoryOption`, `VendorOption` already defined

**Step 1: Add a `FilterOptions` struct and state properties**

At the top of the file, after the imports, add:

```swift
struct TransactionFilterOptions {
    var accounts: [AccountOption] = []
    var categories: [CategoryOption] = []
    var vendors: [VendorOption] = []
}
```

Inside `TransactionsViewModel`, add new `@Published` properties:

```swift
@Published var selectedAccountIds: Set<UUID> = []
@Published var selectedCategoryIds: Set<UUID> = []
@Published var selectedVendorIds: Set<UUID> = []
@Published var filterOptions = TransactionFilterOptions()
@Published var isLoadingFilterOptions = false

var activeFilterCount: Int {
    selectedAccountIds.count + selectedCategoryIds.count + selectedVendorIds.count
}
```

**Step 2: Add `loadFilterOptions()` method**

Add to `TransactionsViewModel`:

```swift
func loadFilterOptions() async {
    guard filterOptions.accounts.isEmpty &&
          filterOptions.categories.isEmpty &&
          filterOptions.vendors.isEmpty else { return }

    isLoadingFilterOptions = true
    defer { isLoadingFilterOptions = false }

    async let accounts: [AccountOption] = (try? repository.apiClient.request(.accountOptions)) ?? []
    async let categories: [CategoryOption] = (try? repository.apiClient.request(.categoryOptions)) ?? []
    async let vendors: PaginatedResponse<VendorOption> = (try? repository.apiClient.request(.vendors)) ?? PaginatedResponse(data: [], nextCursor: nil)

    let (a, c, v) = await (accounts, categories, vendors)
    filterOptions = TransactionFilterOptions(accounts: a, categories: c, vendors: v.data)
}
```

> Note: `repository` is private — expose `apiClient` or add a helper. See Step 3.

**Step 3: Expose apiClient on repository (needed for filter options fetch)**

In `TransactionRepository.swift`, change `private let apiClient` to `let apiClient` (internal access).

**Step 4: Update `load()` to pass selected filter IDs**

In the existing `load(periodId:)` method, update the repository call:

```swift
let response = try await repository.fetchTransactions(
    periodId: periodId,
    direction: selectedDirection,
    accountIds: Array(selectedAccountIds),
    categoryIds: Array(selectedCategoryIds),
    vendorIds: Array(selectedVendorIds)
)
```

Do the same in `loadMore()`:

```swift
let response = try await repository.fetchTransactions(
    periodId: periodId,
    direction: selectedDirection,
    cursor: cursor,
    accountIds: Array(selectedAccountIds),
    categoryIds: Array(selectedCategoryIds),
    vendorIds: Array(selectedVendorIds)
)
```

**Step 5: Add `applyFilters` and `clearFilters` methods**

```swift
func applyFilters(
    accountIds: Set<UUID>,
    categoryIds: Set<UUID>,
    vendorIds: Set<UUID>,
    periodId: UUID
) async {
    selectedAccountIds = accountIds
    selectedCategoryIds = categoryIds
    selectedVendorIds = vendorIds
    await load(periodId: periodId)
}

func clearFilters(periodId: UUID) async {
    selectedAccountIds = []
    selectedCategoryIds = []
    selectedVendorIds = []
    await load(periodId: periodId)
}
```

**Step 6: Build and verify**

```bash
xcodebuild -scheme piggy-pulse-ios -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

**Step 7: Commit**

```bash
git add Features/Transactions/ViewModels/TransactionsViewModel.swift Core/Repositories/TransactionRepository.swift
git commit -m "feat(filters): add filter state and options loading to TransactionsViewModel"
```

---

### Task 3: Create `TransactionFilterSheet`

**Files:**
- Create: `Features/Transactions/Views/TransactionFilterSheet.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let filterOptions: TransactionFilterOptions
    let isLoadingOptions: Bool

    @Binding var selectedAccountIds: Set<UUID>
    @Binding var selectedCategoryIds: Set<UUID>
    @Binding var selectedVendorIds: Set<UUID>

    // Local draft state — only committed on Apply
    @State private var draftAccountIds: Set<UUID>
    @State private var draftCategoryIds: Set<UUID>
    @State private var draftVendorIds: Set<UUID>

    var onApply: (Set<UUID>, Set<UUID>, Set<UUID>) -> Void

    init(
        filterOptions: TransactionFilterOptions,
        isLoadingOptions: Bool,
        selectedAccountIds: Binding<Set<UUID>>,
        selectedCategoryIds: Binding<Set<UUID>>,
        selectedVendorIds: Binding<Set<UUID>>,
        onApply: @escaping (Set<UUID>, Set<UUID>, Set<UUID>) -> Void
    ) {
        self.filterOptions = filterOptions
        self.isLoadingOptions = isLoadingOptions
        self._selectedAccountIds = selectedAccountIds
        self._selectedCategoryIds = selectedCategoryIds
        self._selectedVendorIds = selectedVendorIds
        self.onApply = onApply
        _draftAccountIds = State(initialValue: selectedAccountIds.wrappedValue)
        _draftCategoryIds = State(initialValue: selectedCategoryIds.wrappedValue)
        _draftVendorIds = State(initialValue: selectedVendorIds.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingOptions {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(.ppTextSecondary)
                } else {
                    List {
                        if !filterOptions.accounts.isEmpty {
                            Section("Account") {
                                ForEach(filterOptions.accounts) { account in
                                    filterRow(
                                        title: account.name,
                                        id: account.id,
                                        selected: $draftAccountIds
                                    )
                                }
                            }
                        }

                        if !filterOptions.categories.isEmpty {
                            Section("Category") {
                                ForEach(filterOptions.categories) { category in
                                    filterRow(
                                        title: category.name,
                                        id: category.id,
                                        selected: $draftCategoryIds
                                    )
                                }
                            }
                        }

                        if !filterOptions.vendors.isEmpty {
                            Section("Vendor") {
                                ForEach(filterOptions.vendors) { vendor in
                                    filterRow(
                                        title: vendor.name,
                                        id: vendor.id,
                                        selected: $draftVendorIds
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        draftAccountIds = []
                        draftCategoryIds = []
                        draftVendorIds = []
                    }
                    .foregroundColor(.ppDestructive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draftAccountIds, draftCategoryIds, draftVendorIds)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func filterRow(title: String, id: UUID, selected: Binding<Set<UUID>>) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            if selected.wrappedValue.contains(id) {
                selected.wrappedValue.remove(id)
            } else {
                selected.wrappedValue.insert(id)
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.ppTextPrimary)
                Spacer()
                if selected.wrappedValue.contains(id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.ppPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
```

**Step 2: Build and verify**

```bash
xcodebuild -scheme piggy-pulse-ios -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

**Step 3: Commit**

```bash
git add Features/Transactions/Views/TransactionFilterSheet.swift
git commit -m "feat(filters): add TransactionFilterSheet with multi-select account/category/vendor"
```

---

### Task 4: Wire filter button and sheet into `TransactionsView`

**Files:**
- Modify: `Features/Transactions/Views/TransactionsView.swift`

**Step 1: Add filter sheet state**

In `TransactionsView`, add alongside existing `@State` vars:

```swift
@State private var showFilterSheet = false
```

**Step 2: Add toolbar filter button**

Add a `.toolbar` modifier to the `NavigationStack` content (after `.navigationBarTitleDisplayMode`):

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            showFilterSheet = true
            Task { await viewModel.loadFilterOptions() }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                if viewModel.activeFilterCount > 0 {
                    Text("\(viewModel.activeFilterCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Color.ppPrimary)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
}
```

**Step 3: Add filter sheet presentation**

Add alongside the existing `.sheet` modifiers:

```swift
.sheet(isPresented: $showFilterSheet) {
    TransactionFilterSheet(
        filterOptions: viewModel.filterOptions,
        isLoadingOptions: viewModel.isLoadingFilterOptions,
        selectedAccountIds: $viewModel.selectedAccountIds,
        selectedCategoryIds: $viewModel.selectedCategoryIds,
        selectedVendorIds: $viewModel.selectedVendorIds
    ) { accountIds, categoryIds, vendorIds in
        if let periodId = appState.selectedPeriod?.id {
            Task {
                await viewModel.applyFilters(
                    accountIds: accountIds,
                    categoryIds: categoryIds,
                    vendorIds: vendorIds,
                    periodId: periodId
                )
            }
        }
    }
}
```

**Step 4: Build and verify**

```bash
xcodebuild -scheme piggy-pulse-ios -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

**Step 5: Commit**

```bash
git add Features/Transactions/Views/TransactionsView.swift
git commit -m "feat(filters): wire filter button and sheet into TransactionsView"
```

---

### Task 5: Manual smoke test + final cleanup

**Step 1: Run in simulator**

Build and launch on an iPhone 16 simulator. Navigate to Transactions tab.

**Verify:**
- Filter icon appears in navigation bar top-right
- Tapping it opens the sheet with a loading spinner, then lists accounts/categories/vendors
- Selecting items and tapping Apply reloads the list (fewer results if filters narrow)
- Badge count appears on filter icon matching number of active filters
- "Clear All" resets all checkmarks (Apply still needed to reload)
- Changing the direction tab (All/Incoming/etc.) respects active filters
- Pull-to-refresh respects active filters

**Step 2: Commit if any cleanup needed**

```bash
git commit -m "fix(filters): cleanup after smoke test"
```
