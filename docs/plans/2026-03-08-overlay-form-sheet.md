# Overlay Form Sheet Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 4-step create/edit overlay wizard sheet with a liquid-glass FAB button on the overlays list.

**Architecture:** Single `OverlayFormSheet` view with `@State var currentStep: Int` driving step transitions via `withAnimation`. An `EmojiPickerGrid` component handles emoji selection inline. The FAB on `OverlaysView` matches the existing `addTransactionFAB` pattern from `MainTabView`.

**Tech Stack:** SwiftUI (iOS 26.2), `glassEffect` modifier, existing `APIClient`, `AppState`, `PPSpacing`/`PPRadius`/`PPColor` design tokens.

---

## Reference Files

Before starting, read these files for patterns to follow:

- `Features/Accounts/Views/AddAccountSheet.swift` — sheet structure, toolbar, form card style
- `Features/Periods/Views/CreatePeriodSheet.swift` — multi-section scrollable form
- `App/Features/Navigation/MainTabView.swift` — FAB button pattern (`addTransactionFAB`)
- `Features/Transactions/Views/AddTransactionSheet.swift` — options fetching pattern (accountOptions, categoryOptions, vendors)
- `Core/Network/APIEndpoints.swift` — existing overlay endpoints
- `Core/Models/Overlays.swift` — existing `OverlayItem` model
- `Core/Models/FormOptions.swift` — `CategoryOption`, `AccountOption`, `VendorOption`

---

### Task 1: Add overlay request models to `Overlays.swift`

**Files:**
- Modify: `Core/Models/Overlays.swift`

**Step 1: Add the request and supporting types**

Append to the bottom of `Core/Models/Overlays.swift`:

```swift
// MARK: - Inclusion Mode

enum OverlayInclusionMode: String, Codable, CaseIterable {
    case manual = "manual"
    case rulesBased = "rules_based"
    case includeAll = "include_all"
}

// MARK: - Category Cap

struct CategoryCap: Codable {
    let categoryId: UUID
    let amount: Int64
}

// MARK: - Create/Update Request

struct OverlayRequest: Encodable {
    let name: String
    let icon: String?
    let startDate: String
    let endDate: String
    let inclusionMode: String
    let accountIds: [UUID]?
    let categoryIds: [UUID]?
    let vendorIds: [UUID]?
    let totalCapAmount: Int64?
    let categoryCaps: [CategoryCap]?
}
```

**Step 2: Build the project to verify no compile errors**

In Xcode: `Cmd+B`. Expected: build succeeds.

**Step 3: Commit**

```bash
git add Core/Models/Overlays.swift
git commit -m "feat(overlays): add request model types"
```

---

### Task 2: Create `EmojiPickerGrid.swift`

**Files:**
- Create: `Features/Overlays/Views/EmojiPickerGrid.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct EmojiPickerGrid: View {
    @Binding var selectedEmoji: String?

    private let emojis: [String] = [
        // Travel & Places
        "✈️", "🌍", "🏖️", "🏔️", "🗺️", "🧳", "🚢", "🏕️",
        // Food & Drink
        "🍕", "🍣", "🍷", "☕️", "🍔", "🥗", "🍜", "🧁",
        // Activities & Events
        "🎉", "🎭", "🎵", "⚽️", "🏋️", "🎮", "🎨", "📚",
        // Money & Goals
        "💰", "🎯", "💳", "🏆", "💼", "📊", "🛒", "🏠",
        // Nature & Seasons
        "🌸", "❄️", "🌞", "🍂", "🌈", "🦋", "🌴", "🎄",
        // Misc
        "❤️", "⭐️", "🔥", "💡", "🎁", "🚀", "🦄", "🍀"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: PPSpacing.sm), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: PPSpacing.sm) {
            ForEach(emojis, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)
                    .background(
                        selectedEmoji == emoji
                            ? Color.ppPrimary.opacity(0.2)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: PPRadius.sm)
                            .stroke(
                                selectedEmoji == emoji ? Color.ppPrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedEmoji == emoji {
                            selectedEmoji = nil
                        } else {
                            selectedEmoji = emoji
                        }
                    }
            }
        }
    }
}
```

**Step 2: Build to verify**

`Cmd+B`. Expected: build succeeds.

**Step 3: Commit**

```bash
git add Features/Overlays/Views/EmojiPickerGrid.swift
git commit -m "feat(overlays): add EmojiPickerGrid component"
```

---

### Task 3: Create `OverlayFormSheet.swift` — skeleton + Step 1

**Files:**
- Create: `Features/Overlays/Views/OverlayFormSheet.swift`

**Step 1: Create the file with step state, Step 1 content, and toolbar**

```swift
import SwiftUI

struct OverlayFormSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Mode
    var overlay: OverlayItem? // nil = create, non-nil = edit

    var onSaved: () -> Void

    // MARK: - Step state
    @State private var currentStep = 0
    @State private var stepDirection = 1 // 1 = forward, -1 = back

    // MARK: - Step 1: Basic Info
    @State private var name = ""
    @State private var selectedEmoji: String? = nil
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

    // MARK: - Step 2: Inclusion
    @State private var inclusionMode: OverlayInclusionMode = .manual
    @State private var selectedAccounts: Set<UUID> = []
    @State private var selectedCategories: Set<UUID> = []
    @State private var selectedVendors: Set<UUID> = []

    // MARK: - Step 3: Caps
    @State private var totalCapEnabled = false
    @State private var totalCapText = ""
    @State private var perCategoryCapEnabled = false
    @State private var categoryCapSelections: Set<UUID> = []
    @State private var categoryCapAmounts: [UUID: String] = [:]

    // MARK: - Options
    @State private var accountOptions: [AccountOption] = []
    @State private var categoryOptions: [CategoryOption] = []
    @State private var vendorOptions: [VendorOption] = []
    @State private var isLoadingOptions = false

    // MARK: - Submit
    @State private var isSubmitting = false
    @State private var submitError: String?

    // MARK: - Computed

    private var isEditing: Bool { overlay != nil }

    private var stepTitles: [String] { ["Basics", "Inclusion", "Caps", "Review"] }

    private var step1Valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && endDate > startDate
    }

    private var step2Valid: Bool {
        if inclusionMode == .rulesBased {
            return !selectedAccounts.isEmpty || !selectedCategories.isEmpty || !selectedVendors.isEmpty
        }
        return true
    }

    private var nextEnabled: Bool {
        switch currentStep {
        case 0: return step1Valid
        case 1: return step2Valid
        default: return true
        }
    }

    private var totalCapInCents: Int64? {
        guard totalCapEnabled, !totalCapText.isEmpty else { return nil }
        let cleaned = totalCapText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return nil }
        return Int64(value * 100)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.top, PPSpacing.lg)
                        .padding(.bottom, PPSpacing.md)

                    ScrollView {
                        VStack(spacing: PPSpacing.xl) {
                            stepContent
                        }
                        .padding(PPSpacing.xl)
                    }

                    navigationButtons
                        .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(isEditing ? "Edit Overlay" : "New Overlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
            }
            .task { await loadOptions() }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<stepTitles.count, id: \.self) { index in
                HStack(spacing: PPSpacing.xs) {
                    Circle()
                        .fill(stepDotColor(index))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle().stroke(stepDotBorderColor(index), lineWidth: index == currentStep ? 0 : 1)
                        )

                    Text(stepTitles[index])
                        .font(.ppCaption)
                        .foregroundColor(index == currentStep ? .ppTextPrimary : .ppTextTertiary)
                        .fontWeight(index == currentStep ? .semibold : .regular)
                }

                if index < stepTitles.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.ppPrimary : Color.ppBorder)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, PPSpacing.xs)
                }
            }
        }
    }

    private func stepDotColor(_ index: Int) -> Color {
        if index < currentStep { return .ppPrimary }
        if index == currentStep { return .ppPrimary }
        return .clear
    }

    private func stepDotBorderColor(_ index: Int) -> Color {
        if index <= currentStep { return .clear }
        return .ppBorder
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: step1View
        case 1: step2View
        case 2: step3View
        case 3: step4View
        default: EmptyView()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: PPSpacing.md) {
            if currentStep > 0 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        stepDirection = -1
                        currentStep -= 1
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.ppHeadline)
                        .foregroundColor(.ppTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }
            }

            if currentStep < 3 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        stepDirection = 1
                        currentStep += 1
                    }
                } label: {
                    HStack(spacing: PPSpacing.xs) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.ppHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(nextEnabled ? Color.ppPrimary : Color.ppPrimary.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                }
                .disabled(!nextEnabled)
            } else {
                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(isEditing ? "Save Changes" : "Create Overlay")
                                .font(.ppHeadline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(Color.ppPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                }
                .disabled(isSubmitting)
            }
        }
    }

    // MARK: - Step 1: Basic Info

    private var step1View: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xl) {
            // Name + Emoji card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Basic Information")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                // Name
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("e.g. Italy Trip", text: $name)
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }

                // Emoji
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Emoji").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    EmojiPickerGrid(selectedEmoji: $selectedEmoji)
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

            // Dates card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Date Range")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                HStack {
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text("Start Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden().tint(.ppPrimary)
                            .onChange(of: startDate) {
                                if endDate <= startDate {
                                    endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                                }
                            }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text("End Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        DatePicker("", selection: $endDate, in: Calendar.current.date(byAdding: .day, value: 1, to: startDate)!..., displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden().tint(.ppPrimary)
                    }
                }

                Text("Overlays are temporary and always require both start and end dates.")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
        }
    }

    // MARK: - Load Options

    private func loadOptions() async {
        isLoadingOptions = true
        do {
            async let accounts: [AccountOption] = appState.apiClient.request(.accountOptions)
            async let categories: [CategoryOption] = appState.apiClient.request(.categoryOptions)
            let vendorsResponse: PaginatedResponse<VendorOption> = try await appState.apiClient.request(.vendors)

            accountOptions = try await accounts
            categoryOptions = try await categories
            vendorOptions = vendorsResponse.data
        } catch {
            // Non-fatal — options just won't be available
        }
        isLoadingOptions = false

        // Pre-fill if editing
        if let overlay {
            prefill(from: overlay)
        }
    }

    private func prefill(from overlay: OverlayItem) {
        name = overlay.name
        selectedEmoji = overlay.icon
        if let start = DateFormatter.apiDate.date(from: overlay.startDate) { startDate = start }
        if let end = DateFormatter.apiDate.date(from: overlay.endDate) { endDate = end }
        inclusionMode = OverlayInclusionMode(rawValue: overlay.inclusionMode) ?? .manual
        if let cap = overlay.totalCapAmount {
            totalCapEnabled = true
            totalCapText = String(format: "%.2f", Double(cap) / 100.0)
        }
    }

    // MARK: - Submit

    private func submit() async {
        isSubmitting = true
        submitError = nil

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let categoryCaps: [CategoryCap]? = perCategoryCapEnabled && !categoryCapSelections.isEmpty
            ? categoryCapSelections.compactMap { id -> CategoryCap? in
                guard let text = categoryCapAmounts[id],
                      let value = Double(text.replacingOccurrences(of: ",", with: ".")) else { return nil }
                return CategoryCap(categoryId: id, amount: Int64(value * 100))
            }
            : nil

        let request = OverlayRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedEmoji,
            startDate: fmt.string(from: startDate),
            endDate: fmt.string(from: endDate),
            inclusionMode: inclusionMode.rawValue,
            accountIds: inclusionMode == .rulesBased ? Array(selectedAccounts) : nil,
            categoryIds: inclusionMode == .rulesBased ? Array(selectedCategories) : nil,
            vendorIds: inclusionMode == .rulesBased ? Array(selectedVendors) : nil,
            totalCapAmount: totalCapInCents,
            categoryCaps: categoryCaps
        )

        do {
            if let overlay {
                try await appState.apiClient.request(.updateOverlay(overlay.id), body: request)
            } else {
                try await appState.apiClient.request(.createOverlay, body: request)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch let e as APIError {
            submitError = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            submitError = String(localized: "Failed to save overlay.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSubmitting = false
    }

    // MARK: - Stubs (filled in next tasks)

    @ViewBuilder private var step2View: some View { Text("Step 2").foregroundColor(.ppTextSecondary) }
    @ViewBuilder private var step3View: some View { Text("Step 3").foregroundColor(.ppTextSecondary) }
    @ViewBuilder private var step4View: some View { Text("Step 4").foregroundColor(.ppTextSecondary) }
}
```

**Step 2: Build to verify**

`Cmd+B`. Expected: build succeeds (stubs keep it compilable).

**Step 3: Commit**

```bash
git add Features/Overlays/Views/OverlayFormSheet.swift
git commit -m "feat(overlays): add OverlayFormSheet skeleton with Step 1 and submit logic"
```

---

### Task 4: Add FAB button to `OverlaysView` + wire sheet

**Files:**
- Modify: `Features/Overlays/Views/OverlaysView.swift`

**Step 1: Add state and FAB**

Add to `OverlaysView`:
```swift
@State private var showCreateSheet = false
```

Wrap the existing `List { ... }` in a `ZStack`:
```swift
ZStack(alignment: .bottomTrailing) {
    List { ... } // existing list

    // FAB
    Button {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showCreateSheet = true
    } label: {
        Image(systemName: "plus")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.ppPrimary)
            .frame(width: 56, height: 56)
            .glassEffect(.regular, in: Circle())
    }
    .padding(.trailing, PPSpacing.lg)
    .padding(.bottom, PPSpacing.xl)
}
.sheet(isPresented: $showCreateSheet) {
    OverlayFormSheet(overlay: nil, onSaved: {
        Task { await load() }
    })
    .environmentObject(appState)
}
```

**Step 2: Update the empty state text**

Change the empty state description from:
```
"Create overlays from the web app to track temporary spending goals."
```
to:
```
"Tap + to create your first overlay."
```

**Step 3: Build to verify**

`Cmd+B`. Expected: build succeeds.

**Step 4: Commit**

```bash
git add Features/Overlays/Views/OverlaysView.swift
git commit -m "feat(overlays): add liquid glass FAB and sheet presentation to OverlaysView"
```

---

### Task 5: Implement Step 2 — Inclusion Rules

**Files:**
- Modify: `Features/Overlays/Views/OverlayFormSheet.swift`

**Step 1: Replace the `step2View` stub**

Replace `@ViewBuilder private var step2View: some View { Text("Step 2").foregroundColor(.ppTextSecondary) }` with:

```swift
@ViewBuilder private var step2View: some View {
    VStack(alignment: .leading, spacing: PPSpacing.xl) {
        // Mode selection card
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("Inclusion Rules")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            VStack(spacing: PPSpacing.sm) {
                inclusionModeRow(.manual, title: "Manual", description: "You decide what to include manually.", recommended: true)
                inclusionModeRow(.rulesBased, title: "Rules-based", description: "Include transactions automatically from category, vendor, or account rules.", recommended: false)
                inclusionModeRow(.includeAll, title: "Include everything", description: "Include every transaction inside the date range.", recommended: false)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

        // Rules pickers (only when rules-based)
        if inclusionMode == .rulesBased {
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Rules")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                if isLoadingOptions {
                    HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                } else {
                    multiSelectSection(
                        title: "Accounts",
                        items: accountOptions.map { ($0.id, "\($0.icon) \($0.name)") },
                        selected: $selectedAccounts
                    )
                    multiSelectSection(
                        title: "Categories",
                        items: categoryOptions.map { ($0.id, "\($0.icon) \($0.name)") },
                        selected: $selectedCategories
                    )
                    multiSelectSection(
                        title: "Vendors",
                        items: vendorOptions.map { ($0.id, $0.name) },
                        selected: $selectedVendors
                    )
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
        }
    }
}

private func inclusionModeRow(_ mode: OverlayInclusionMode, title: String, description: String, recommended: Bool) -> some View {
    Button {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) { inclusionMode = mode }
    } label: {
        HStack(alignment: .top, spacing: PPSpacing.md) {
            Image(systemName: inclusionMode == mode ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(inclusionMode == mode ? .ppPrimary : .ppTextTertiary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                HStack(spacing: PPSpacing.xs) {
                    Text(title)
                        .font(.ppHeadline)
                        .foregroundColor(.ppTextPrimary)
                    if recommended {
                        Text("Recommended")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.ppPrimary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.ppPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    }
                }
                Text(description)
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(PPSpacing.md)
        .background(inclusionMode == mode ? Color.ppPrimary.opacity(0.06) : Color.ppSurface)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.md)
                .stroke(inclusionMode == mode ? Color.ppPrimary.opacity(0.4) : Color.ppBorder, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
}

private func multiSelectSection(title: String, items: [(UUID, String)], selected: Binding<Set<UUID>>) -> some View {
    VStack(alignment: .leading, spacing: PPSpacing.sm) {
        HStack {
            Text(title)
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
            Spacer()
            if !selected.wrappedValue.isEmpty {
                Text("\(selected.wrappedValue.count)")
                    .font(.ppCaption).foregroundColor(.white)
                    .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                    .background(Color.ppPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
            }
        }

        if items.isEmpty {
            Text("No \(title.lowercased()) available")
                .font(.ppCallout).foregroundColor(.ppTextTertiary)
        } else {
            VStack(spacing: PPSpacing.xs) {
                ForEach(items, id: \.0) { id, label in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selected.wrappedValue.contains(id) {
                            selected.wrappedValue.remove(id)
                        } else {
                            selected.wrappedValue.insert(id)
                        }
                    } label: {
                        HStack {
                            Text(label).font(.ppBody).foregroundColor(.ppTextPrimary)
                            Spacer()
                            if selected.wrappedValue.contains(id) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.ppPrimary)
                            }
                        }
                        .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                        .background(selected.wrappedValue.contains(id) ? Color.ppPrimary.opacity(0.06) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

**Step 2: Build to verify**

`Cmd+B`. Expected: build succeeds.

**Step 3: Commit**

```bash
git add Features/Overlays/Views/OverlayFormSheet.swift
git commit -m "feat(overlays): implement Step 2 inclusion rules"
```

---

### Task 6: Implement Step 3 — Caps

**Files:**
- Modify: `Features/Overlays/Views/OverlayFormSheet.swift`

**Step 1: Replace the `step3View` stub**

Replace `@ViewBuilder private var step3View: some View { Text("Step 3").foregroundColor(.ppTextSecondary) }` with:

```swift
@ViewBuilder private var step3View: some View {
    VStack(alignment: .leading, spacing: PPSpacing.xl) {
        // Total cap card
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Toggle(isOn: $totalCapEnabled.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Amount Cap")
                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                    Text("Set a spending limit for the entire overlay.")
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                }
            }
            .tint(.ppPrimary)

            if totalCapEnabled {
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Cap Amount").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    HStack {
                        Text(appState.currencySymbol).font(.ppBody).foregroundColor(.ppTextSecondary)
                        TextField("0.00", text: $totalCapText).keyboardType(.decimalPad)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                    }
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

        // Per-category caps card
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Toggle(isOn: $perCategoryCapEnabled.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Per-Category Cap")
                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                    Text("Limit spending per category within this overlay.")
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                }
            }
            .tint(.ppPrimary)

            if perCategoryCapEnabled {
                if categoryOptions.isEmpty {
                    Text("No categories available")
                        .font(.ppCallout).foregroundColor(.ppTextTertiary)
                } else {
                    VStack(spacing: PPSpacing.sm) {
                        ForEach(categoryOptions) { category in
                            VStack(spacing: PPSpacing.sm) {
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if categoryCapSelections.contains(category.id) {
                                            categoryCapSelections.remove(category.id)
                                            categoryCapAmounts.removeValue(forKey: category.id)
                                        } else {
                                            categoryCapSelections.insert(category.id)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("\(category.icon) \(category.name)")
                                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Image(systemName: categoryCapSelections.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(categoryCapSelections.contains(category.id) ? .ppPrimary : .ppTextTertiary)
                                    }
                                }
                                .buttonStyle(.plain)

                                if categoryCapSelections.contains(category.id) {
                                    HStack {
                                        Text(appState.currencySymbol).font(.ppBody).foregroundColor(.ppTextSecondary)
                                        TextField("0.00", text: Binding(
                                            get: { categoryCapAmounts[category.id] ?? "" },
                                            set: { categoryCapAmounts[category.id] = $0 }
                                        ))
                                        .keyboardType(.decimalPad)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.sm)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                    .padding(.leading, PPSpacing.xl)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }
}
```

**Note:** `appState.currencySymbol` may not exist yet. Check `AppState` — if it only has `currencyCode`, add a computed property or use a helper. Alternatively use `appState.currencyCode` as the prefix. Check `Core/Utilities/CurrencyHelper.swift` for existing helpers.

**Step 2: Build to verify**

`Cmd+B`. Fix any missing property errors (e.g., replace `appState.currencySymbol` with `appState.currencyCode` if needed).

**Step 3: Commit**

```bash
git add Features/Overlays/Views/OverlayFormSheet.swift
git commit -m "feat(overlays): implement Step 3 caps"
```

---

### Task 7: Implement Step 4 — Review

**Files:**
- Modify: `Features/Overlays/Views/OverlayFormSheet.swift`

**Step 1: Replace the `step4View` stub**

Replace `@ViewBuilder private var step4View: some View { Text("Step 4").foregroundColor(.ppTextSecondary) }` with:

```swift
@ViewBuilder private var step4View: some View {
    VStack(alignment: .leading, spacing: PPSpacing.xl) {
        // Edit mode warning
        if isEditing {
            HStack(spacing: PPSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.ppAmber)
                Text("Changing date range or inclusion mode updates which transactions may belong to this overlay.")
                    .font(.ppCallout)
                    .foregroundColor(.ppAmber)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppAmber.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppAmber.opacity(0.3), lineWidth: 1))
        }

        // Summary card
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("Summary")
                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

            // Name + emoji
            reviewRow(label: "Name") {
                HStack(spacing: PPSpacing.xs) {
                    if let emoji = selectedEmoji { Text(emoji).font(.ppBody) }
                    Text(name.isEmpty ? "—" : name).font(.ppBody).foregroundColor(.ppTextPrimary)
                }
            }

            Divider().background(Color.ppBorder)

            // Date range
            reviewRow(label: "Date Range") {
                Text(formatReviewDateRange())
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
            }

            Divider().background(Color.ppBorder)

            // Inclusion
            reviewRow(label: "Inclusion") {
                VStack(alignment: .trailing, spacing: PPSpacing.xs) {
                    Text(inclusionModeLabel(inclusionMode))
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    if inclusionMode == .rulesBased {
                        let parts = [
                            selectedAccounts.isEmpty ? nil : "\(selectedAccounts.count) account\(selectedAccounts.count == 1 ? "" : "s")",
                            selectedCategories.isEmpty ? nil : "\(selectedCategories.count) categor\(selectedCategories.count == 1 ? "y" : "ies")",
                            selectedVendors.isEmpty ? nil : "\(selectedVendors.count) vendor\(selectedVendors.count == 1 ? "" : "s")"
                        ].compactMap { $0 }
                        Text(parts.joined(separator: ", "))
                            .font(.ppCaption).foregroundColor(.ppTextSecondary)
                    }
                }
            }

            Divider().background(Color.ppBorder)

            // Total cap
            reviewRow(label: "Total Cap") {
                Text(totalCapEnabled && totalCapInCents != nil
                     ? formatCentsForReview(totalCapInCents!)
                     : "None")
                    .font(.ppBody).foregroundColor(totalCapEnabled ? .ppTextPrimary : .ppTextTertiary)
            }

            // Per-category caps
            if perCategoryCapEnabled && !categoryCapSelections.isEmpty {
                Divider().background(Color.ppBorder)
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Per-Category Caps").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextSecondary)
                    ForEach(categoryOptions.filter { categoryCapSelections.contains($0.id) }) { cat in
                        HStack {
                            Text("\(cat.icon) \(cat.name)").font(.ppBody).foregroundColor(.ppTextPrimary)
                            Spacer()
                            if let text = categoryCapAmounts[cat.id],
                               let value = Double(text.replacingOccurrences(of: ",", with: ".")) {
                                Text(formatCentsForReview(Int64(value * 100)))
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                            } else {
                                Text("—").font(.ppBody).foregroundColor(.ppTextTertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

        // Submit error
        if let error = submitError {
            Text(error)
                .font(.ppCallout).foregroundColor(.ppDestructive)
                .multilineTextAlignment(.center)
        }
    }
}

private func reviewRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
    HStack(alignment: .top) {
        Text(label).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextSecondary)
        Spacer()
        content()
    }
}

private func formatReviewDateRange() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "MMM d, yyyy"
    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    return "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate)) · \(days) days"
}

private func inclusionModeLabel(_ mode: OverlayInclusionMode) -> String {
    switch mode {
    case .manual: return "Manual"
    case .rulesBased: return "Rules-based"
    case .includeAll: return "Include everything"
    }
}

private func formatCentsForReview(_ cents: Int64) -> String {
    let value = Double(cents) / 100.0
    return String(format: "%.2f %@", value, appState.currencyCode)
}
```

**Step 2: Build to verify**

`Cmd+B`. Expected: build succeeds.

**Step 3: Commit**

```bash
git add Features/Overlays/Views/OverlayFormSheet.swift
git commit -m "feat(overlays): implement Step 4 review"
```

---

### Task 8: Wire edit mode from `OverlaysView`

**Files:**
- Modify: `Features/Overlays/Views/OverlaysView.swift`

**Step 1: Add edit sheet state**

```swift
@State private var overlayToEdit: OverlayItem?
```

**Step 2: Add a long-press or edit button on `overlayCard`**

Add a context menu to the `overlayCard` closure:

```swift
overlayCard(overlay)
    .contextMenu {
        Button {
            overlayToEdit = overlay
        } label: {
            Label("Edit Overlay", systemImage: "pencil")
        }
    }
```

**Step 3: Add the edit sheet**

Add alongside the existing `.sheet(isPresented: $showCreateSheet)`:

```swift
.sheet(item: $overlayToEdit) { overlay in
    OverlayFormSheet(overlay: overlay, onSaved: {
        Task { await load() }
    })
    .environmentObject(appState)
}
```

**Step 4: Build to verify**

`Cmd+B`. Expected: build succeeds.

**Step 5: Commit**

```bash
git add Features/Overlays/Views/OverlaysView.swift
git commit -m "feat(overlays): wire edit mode via context menu on overlay card"
```

---

### Task 9: Manual verification checklist

Run the app on a simulator (iOS 26+) and verify:

- [ ] Overlays list shows the liquid-glass FAB in the bottom-right corner
- [ ] Tapping FAB opens the sheet — Step 1 visible with step indicator showing "Basics" active
- [ ] Filling in name + dates enables the "Next" button
- [ ] Emoji grid renders, tapping selects with primary ring, tapping again deselects
- [ ] Step 2: mode cards respond to taps with animation; rules-based expands multi-select pickers
- [ ] Step 3: toggles animate expand/collapse; per-category rows show amount fields when selected
- [ ] Step 4: summary reflects all choices; edit warning shows in edit mode
- [ ] "Create Overlay" calls the API and dismisses on success
- [ ] X button dismisses at any step without confirmation
- [ ] Long-pressing an overlay card shows "Edit Overlay" context menu; opens sheet pre-filled

**Step: Commit if all checks pass**

```bash
git commit --allow-empty -m "chore: manual verification complete for overlay form sheet"
```

---

### Task 10: Push and open draft PR

```bash
git push origin main
gh pr create --draft --title "feat(overlays): create/edit overlay wizard sheet" \
  --body "$(cat <<'EOF'
## Summary
- 4-step wizard sheet (Basics → Inclusion → Caps → Review) for creating and editing overlays
- Liquid-glass FAB button on the overlays list
- Inline emoji picker grid with 48 curated emojis
- Edit mode pre-fills all fields and shows a warning about data impact

## Test plan
- [ ] Create overlay (all inclusion modes)
- [ ] Create overlay with total cap + per-category caps
- [ ] Edit existing overlay — verify pre-fill and warning banner
- [ ] Cancel at every step — no data submitted
- [ ] FAB visible and functional on overlays list
EOF
)"
```
