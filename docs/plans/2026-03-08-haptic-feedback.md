# Haptic Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add haptic feedback to all meaningful user interactions across the app.

**Architecture:** Call `UINotificationFeedbackGenerator` and `UIImpactFeedbackGenerator` inline at each action site — no shared utility needed. All call sites are in SwiftUI views which run on `@MainActor`, satisfying UIKit's main-thread requirement.

**Tech Stack:** `UIKit` (UINotificationFeedbackGenerator, UIImpactFeedbackGenerator) — already available, no imports needed in SwiftUI files that already import SwiftUI on iOS.

**Haptic map:**
| Trigger | Generator |
|---------|-----------|
| Successful create / save / update | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |
| API error (any catch block that sets errorMessage) | `UINotificationFeedbackGenerator().notificationOccurred(.error)` |
| Destructive confirm (delete / archive) | `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` |
| FAB tap (Add Transaction button) | `UIImpactFeedbackGenerator(style: .light).impactOccurred()` |
| Log out | `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` |

---

## Task 1: Git setup

**Step 1: Pull main and create branch**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git checkout main && git pull
git checkout -b feat/haptic-feedback
```

---

## Task 2: FAB and Logout — `MainTabView.swift`

**File:** `App/Features/Navigation/MainTabView.swift`

**Context:** The FAB button sets `showAddTransaction = true`. The logout button calls `appState.logout()`.

**Step 1: Read the file**

Read `App/Features/Navigation/MainTabView.swift` to find the exact FAB button body and logout button body.

**Step 2: Add light impact to FAB**

In the FAB button action, add the haptic before `showAddTransaction = true`:
```swift
Button {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    showAddTransaction = true
} label: {
```

**Step 3: Add medium impact to Logout**

In the logout button action, add before `Task { await appState.logout() }`:
```swift
Button {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    Task { await appState.logout() }
} label: {
```

**Step 4: Commit**

```bash
git add App/Features/Navigation/MainTabView.swift
git commit -m "feat(haptics): add light impact on FAB tap, medium on logout"
```

---

## Task 3: Transaction sheets

**Files:**
- `Features/Transactions/Views/AddTransactionSheet.swift`
- `Features/Transactions/Views/EditTransactionSheet.swift`

### AddTransactionSheet

**Context:** `createTransaction()` function. Success path: after `try await appState.apiClient.request(.createTransaction, body: request)`, before `onCreated()` and `dismiss()`. Error paths: both catch blocks that set `errorMessage`.

**Step 1: Read the file**

Read `Features/Transactions/Views/AddTransactionSheet.swift`.

**Step 2: Add success haptic**

In `createTransaction()`, after the successful API call line, before `onCreated()`:
```swift
try await appState.apiClient.request(.createTransaction, body: request)
UINotificationFeedbackGenerator().notificationOccurred(.success)
onCreated()
dismiss()
```

**Step 3: Add error haptics**

In each catch block that assigns `errorMessage`, add the error haptic on the next line:
```swift
} catch let error as APIError {
    errorMessage = error.errorDescription
    UINotificationFeedbackGenerator().notificationOccurred(.error)
} catch {
    errorMessage = String(localized: "Failed to create transaction.")
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}
```

Also in the guard failure before `isLoading = false`:
```swift
errorMessage = String(localized: "Please select a category and account.")
UINotificationFeedbackGenerator().notificationOccurred(.error)
isLoading = false
return
```

And in `loadOptions()` catch:
```swift
} catch {
    errorMessage = String(localized: "Failed to load form options.")
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}
```

### EditTransactionSheet

**Step 4: Apply the same pattern to `EditTransactionSheet.swift`**

In `update()`:
- After successful API call, before `onUpdated(); dismiss()`:
  ```swift
  try await appState.apiClient.request(.updateTransaction(transaction.id), body: req)
  UINotificationFeedbackGenerator().notificationOccurred(.success)
  onUpdated(); dismiss()
  ```
- In each catch block: add `UINotificationFeedbackGenerator().notificationOccurred(.error)` after each `errorMessage = ...` assignment.

In `loadOptions()` catch: add error haptic after errorMessage assignment.

**Step 5: Also add medium impact to `deleteTransaction` in `TransactionsView.swift`**

Read `Features/Transactions/Views/TransactionsView.swift`. Find `deleteTransaction(_ tx:)`. Add medium impact at the start of the function body, before the `do {`:
```swift
private func deleteTransaction(_ tx: Transaction) async {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    do {
        try await appState.apiClient.requestVoid(.deleteTransaction(tx.id))
```

**Step 6: Commit**

```bash
git add \
  Features/Transactions/Views/AddTransactionSheet.swift \
  Features/Transactions/Views/EditTransactionSheet.swift \
  Features/Transactions/Views/TransactionsView.swift
git commit -m "feat(haptics): add success/error/destructive haptics to transaction screens"
```

---

## Task 4: Account sheets and list

**Files:**
- `Features/Accounts/Views/AddAccountSheet.swift`
- `Features/Accounts/Views/EditAccountSheet.swift`
- `Features/Accounts/Views/AccountsView.swift`

**Step 1: Read all three files**

**Step 2: AddAccountSheet — `create()` function**

Success: after `try await appState.apiClient.request(.createAccount, body: req)`, before `onCreated(); dismiss()`:
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
onCreated(); dismiss()
```
Error: add `UINotificationFeedbackGenerator().notificationOccurred(.error)` after each `errorMessage = ...` in catch blocks.

**Step 3: EditAccountSheet — `save()` function**

Same pattern: success haptic before `onUpdated(); dismiss()`, error haptics in catch blocks.

**Step 4: AccountsView — `deleteAccount` and `archiveAccount`**

In `deleteAccount(_ account:)`, add at the start of the function body:
```swift
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

In `archiveAccount(_ account:)`, add the same at the start.

**Step 5: Commit**

```bash
git add \
  Features/Accounts/Views/AddAccountSheet.swift \
  Features/Accounts/Views/EditAccountSheet.swift \
  Features/Accounts/Views/AccountsView.swift
git commit -m "feat(haptics): add success/error/destructive haptics to account screens"
```

---

## Task 5: Category sheets and list

**Files:**
- `Features/Categories/Views/AddCategorySheet.swift`
- `Features/Categories/Views/EditCategorySheet.swift`
- `Features/Categories/Views/CategoriesView.swift`

**Step 1: Read all three files**

**Step 2: AddCategorySheet — `create()` function**

Success: after `try await appState.apiClient.request(.createCategory, body: req)`, before `onCreated(); dismiss()`:
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
onCreated(); dismiss()
```
Error: add error haptic after each `errorMessage = ...` in catch blocks.

**Step 3: EditCategorySheet — `save()` function**

Same pattern: success haptic before `onUpdated(); dismiss()`, error haptics in catch blocks.

**Step 4: CategoriesView — `deleteCategory` and `archiveCategory`**

Add `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` at the start of each function body.

**Step 5: Commit**

```bash
git add \
  Features/Categories/Views/AddCategorySheet.swift \
  Features/Categories/Views/EditCategorySheet.swift \
  Features/Categories/Views/CategoriesView.swift
git commit -m "feat(haptics): add success/error/destructive haptics to category screens"
```

---

## Task 6: Vendor sheets and list

**Files:**
- `Features/Vendors/Views/AddVendorSheet.swift`
- `Features/Vendors/Views/EditVendorSheet.swift`
- `Features/Vendors/Views/VendorsView.swift`

**Step 1: Read all three files**

**Step 2: AddVendorSheet — `create()` function**

Success: after `try await appState.apiClient.request(.createVendor, body: req)`, before `onCreated(); dismiss()`:
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
onCreated(); dismiss()
```
Error: add error haptic after each `errorMessage = ...` in catch blocks.

**Step 3: EditVendorSheet — `save()` function**

Same pattern.

**Step 4: VendorsView — `deleteVendor` and `archiveVendor`**

Add `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` at the start of each function body.

**Step 5: Commit**

```bash
git add \
  Features/Vendors/Views/AddVendorSheet.swift \
  Features/Vendors/Views/EditVendorSheet.swift \
  Features/Vendors/Views/VendorsView.swift
git commit -m "feat(haptics): add success/error/destructive haptics to vendor screens"
```

---

## Task 7: Settings sheets

**Files:**
- `Features/Settings/Views/EditProfileSheet.swift`
- `Features/Settings/Views/ChangePasswordSheet.swift`

**Step 1: Read both files**

**Step 2: EditProfileSheet — `save()` function**

Success path ends with `dismiss()`. Add before it:
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
dismiss()
```
Error: add error haptic after each `errorMessage = ...` in catch blocks.

**Step 3: ChangePasswordSheet — `changePassword()` function**

Success path sets `success = true`. Add after:
```swift
success = true
UINotificationFeedbackGenerator().notificationOccurred(.success)
```
Error: add error haptic after each `errorMessage = ...` in catch blocks.

**Step 4: Commit**

```bash
git add \
  Features/Settings/Views/EditProfileSheet.swift \
  Features/Settings/Views/ChangePasswordSheet.swift
git commit -m "feat(haptics): add success/error haptics to settings sheets"
```

---

## Task 8: Period sheets

**Files:**
- `Features/Periods/Views/CreatePeriodSheet.swift`
- `Features/Periods/Views/AutoCreationView.swift`

**Step 1: Read both files**

**Step 2: CreatePeriodSheet — success/error function**

Find the function that calls the create API. Success path calls `onCreated()` then `dismiss()`. Add before them:
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
onCreated()
dismiss()
```
Error: add error haptic after each `errorMessage = ...` in catch blocks.

**Step 3: AutoCreationView — save and disable functions**

Find the save schedule function. Add success haptic on the success path, error haptic in catch blocks.

Find the disable function. Add success haptic on success path, error haptic in catch blocks.

**Step 4: Commit**

```bash
git add \
  Features/Periods/Views/CreatePeriodSheet.swift \
  Features/Periods/Views/AutoCreationView.swift
git commit -m "feat(haptics): add success/error haptics to period screens"
```

---

## Task 9: Push and open draft PR

**Step 1: Push**

```bash
git push -u origin feat/haptic-feedback
```

**Step 2: Open draft PR**

```bash
gh pr create \
  --title "feat(haptics): add haptic feedback to all user interactions" \
  --body "$(cat <<'EOF'
## Summary

- `.success` notification haptic on all successful create/save/update operations (transactions, accounts, categories, vendors, profile, password, periods, auto-creation schedule)
- `.error` notification haptic whenever an API error sets an error message
- `.medium` impact haptic on all destructive actions (delete/archive for transactions, accounts, categories, vendors)
- `.light` impact haptic on the Add Transaction FAB tap
- `.medium` impact haptic on logout

Uses `UINotificationFeedbackGenerator` and `UIImpactFeedbackGenerator` inline at each call site — no wrapper utility.

## Test plan

- [ ] Create a transaction → feel success haptic on dismiss
- [ ] Trigger a form validation error → feel error haptic
- [ ] Swipe-delete a transaction and confirm → feel medium impact
- [ ] Tap the Add Transaction FAB → feel light impact
- [ ] Tap Log out → feel medium impact
- [ ] Verify on a physical device (simulator does not produce haptics)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --draft
```
