# FAB with Liquid Glass Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the add-transaction button inside `PeriodSelectorBar` with a floating action button (FAB) that uses the iOS 26 liquid glass effect, visible only on Dashboard and Transactions tabs.

**Architecture:** A `ZStack` wraps the `TabView` in `MainTabView`. The FAB is pinned bottom-trailing using `.safeAreaInset(edge: .bottom)` so it floats naturally above the tab bar without hardcoded offsets. It uses `.glassEffect(.regular, in: Circle())` for the liquid glass look. Visibility is driven by `selectedTab` with a spring animation.

**Tech Stack:** SwiftUI, iOS 26+, `.glassEffect()` API, SF Symbols

---

### Task 1: Remove add-transaction from PeriodSelectorBar

**Files:**
- Modify: `Features/Navigation/PeriodSelectorBar.swift`

**Step 1: Remove the `onAddTransaction` parameter and the button**

In `PeriodSelectorBar`, delete:
- The `var onAddTransaction: (() -> Void)? = nil` property
- The entire `if let onAdd = onAddTransaction { ... }` block (lines 67–74)
- The `HStack(spacing: 0)` wrapper can become a plain `Button` or stay as-is — keep the `HStack` but remove the trailing button

The `body` should now just be the period selector button filling the full width, with no trailing `+` button.

**Step 2: Build to confirm no compiler errors**

In Xcode, press ⌘+B. Expected: build succeeds (there will be one error in MainTabView for the now-removed parameter — that's expected, fix in Task 2).

---

### Task 2: Update MainTabView — remove parameter, add FAB

**Files:**
- Modify: `App/Features/Navigation/MainTabView.swift`

**Step 1: Fix the PeriodSelectorBar call**

Find:
```swift
PeriodSelectorBar(onAddTransaction: { showAddTransaction = true })
```
Replace with:
```swift
PeriodSelectorBar()
```

**Step 2: Add a computed property for FAB visibility**

Add this inside `MainTabView`:
```swift
private var showFAB: Bool {
    selectedTab == 0 || selectedTab == 1
}
```

**Step 3: Wrap the TabView body in a ZStack with safeAreaInset**

The current `body` returns a `TabView(...)` with modifiers chained. Wrap it so the FAB sits above the tab bar:

```swift
var body: some View {
    ZStack(alignment: .bottomTrailing) {
        TabView(selection: $selectedTab) {
            // ... existing tabs unchanged ...
        }
        .tabViewBottomAccessory {
            PeriodSelectorBar()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.ppPrimary)
        .background(Color.ppBackground)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionSheet(onCreated: { selectedTab = 1 })
                .environmentObject(appState)
        }

        if showFAB {
            addTransactionFAB
        }
    }
}
```

**Step 4: Add the FAB view property**

```swift
private var addTransactionFAB: some View {
    Button {
        showAddTransaction = true
    } label: {
        Image(systemName: "plus")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.ppPrimary)
            .frame(width: 56, height: 56)
            .glassEffect(.regular, in: Circle())
    }
    .padding(.trailing, PPSpacing.lg)
    .padding(.bottom, PPSpacing.xl)
    .transition(.scale(scale: 0.8).combined(with: .opacity))
    .animation(.spring(duration: 0.3), value: showFAB)
}
```

> Note: `.padding(.bottom, PPSpacing.xl)` gives clearance above the tab bar accessory. Adjust if the FAB overlaps the `PeriodSelectorBar` — you may need to increase to `PPSpacing.xxl` depending on the accessory bar height.

**Step 5: Build and run in Simulator**

Press ⌘+R. Verify:
- FAB appears on Dashboard (tab 0) and Transactions (tab 1)
- FAB disappears with spring animation when switching to Periods (tab 2) or More (tab 3)
- Tapping FAB opens `AddTransactionSheet`
- FAB has liquid glass appearance matching the tab bar
- `PeriodSelectorBar` no longer shows a `+` button

**Step 6: Commit**

```bash
git add App/Features/Navigation/MainTabView.swift Features/Navigation/PeriodSelectorBar.swift
git commit -m "feat(navigation): replace accessory bar add button with liquid glass FAB"
```
