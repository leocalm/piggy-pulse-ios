import SwiftUI

struct OverlayFormSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    var overlay: OverlayItem?
    var onSaved: () -> Void

    // MARK: - Step State

    @State private var currentStep = 0

    // Step 1 — Basics
    @State private var name: String = ""
    @State private var selectedEmoji: String? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

    // Step 2 — Inclusion
    @State private var inclusionMode: OverlayInclusionMode = .includeAll
    @State private var selectedAccountIds: Set<UUID> = []
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var selectedVendorIds: Set<UUID> = []

    // Step 3 — Caps
    @State private var isTotalCapEnabled: Bool = false
    @State private var isPerCategoryCapEnabled: Bool = false
    @State private var totalCapText: String = ""
    @State private var categoryCaps: [UUID: String] = [:]
    @State private var categoryCapSelections: Set<UUID> = []

    // Options
    @State private var accountOptions: [AccountOption] = []
    @State private var categoryOptions: [CategoryOption] = []
    @State private var vendorOptions: [VendorOption] = []

    // UI State
    @State private var isLoading = false
    @State private var isLoadingOptions = false
    @State private var errorMessage: String?

    // MARK: - Computed

    private var isEditMode: Bool { overlay != nil }

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = appState.currencyCode
        return fmt.currencySymbol ?? appState.currencyCode
    }

    private var step1Valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var minEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
    }

    private var totalCapAmountCents: Int64? {
        let cleaned = totalCapText.replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let value = Double(cleaned) else { return nil }
        return Int64(value * 100)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground(colorScheme).ignoresSafeArea()
                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.top, PPSpacing.lg)
                        .padding(.bottom, PPSpacing.md)

                    Divider().background(Color.ppBorder(colorScheme))

                    ScrollView {
                        VStack(spacing: PPSpacing.xl) {
                            if let error = errorMessage {
                                Text(error)
                                    .font(.ppCallout)
                                    .foregroundColor(.ppDestructive)
                                    .multilineTextAlignment(.center)
                            }

                            currentStepView
                        }
                        .padding(PPSpacing.xl)
                        .padding(.bottom, PPSpacing.xl)
                    }
                    .safeAreaInset(edge: .bottom) {
                        navigationButtons
                            .padding(.horizontal, PPSpacing.xl)
                            .padding(.vertical, PPSpacing.md)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Overlay" : "New Overlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary(colorScheme))
                }
            }
            .task {
                await loadOptions()
                if let overlay = overlay {
                    prefill(from: overlay)
                }
            }
            .onChange(of: startDate) { _, newStart in
                if endDate <= newStart {
                    endDate = Calendar.current.date(byAdding: .day, value: 1, to: newStart) ?? newStart
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        let labels = ["Basics", "Inclusion", "Caps", "Review"]
        return HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                VStack(spacing: 4) {
                    Circle()
                        .fill(dotColor(for: index))
                        .overlay(
                            Circle().stroke(
                                index > currentStep ? Color.ppBorder(colorScheme) : Color.clear,
                                lineWidth: 1.5
                            )
                        )
                        .frame(width: 12, height: 12)
                    Text(labels[index])
                        .font(.ppCaption)
                        .foregroundColor(index == currentStep ? .ppPrimary : .ppTextTertiary(colorScheme))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(labels[index]), step \(index + 1) of \(labels.count)\(index == currentStep ? ", current" : index < currentStep ? ", completed" : "")")
                if index < 3 {
                    Rectangle()
                        .fill(index < currentStep ? Color.ppPrimary.opacity(0.5) : Color.ppBorder(colorScheme))
                        .frame(height: 1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)
                }
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentStep { return Color.ppPrimary.opacity(0.5) }
        if index == currentStep { return Color.ppPrimary }
        return Color.clear
    }

    // MARK: - Step Router

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0: step1View
        case 1: step2View
        case 2: step3View
        case 3: step4View
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Basics

    private var step1View: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xl) {
            // Name & Emoji card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Overlay Details")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                // Name field
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("e.g. Summer Vacation Budget", text: $name)
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary(colorScheme))
                        .padding(.horizontal, PPSpacing.lg)
                        .padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                }

                // Emoji picker
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Icon (optional)")
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                    EmojiPickerGrid(selectedEmoji: $selectedEmoji)
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))

            // Date range card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Date Range")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                // Start Date
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Start Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.ppPrimary)
                }

                // End Date
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("End Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    DatePicker(
                        "",
                        selection: $endDate,
                        in: minEndDate...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.ppPrimary)
                }

                // Disclaimer
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary(colorScheme))
                    Text("Overlays are temporary and always require both start and end dates.")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(PPSpacing.md)
                .background(Color.ppSurface(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
        }
    }

    // MARK: - Step 2: Inclusion

    @ViewBuilder private var step2View: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xl) {
            // Mode selection card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Inclusion Rules")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                VStack(spacing: PPSpacing.sm) {
                    inclusionModeRow(.manual, title: "Manual", description: "You decide what to include manually.", recommended: true)
                    inclusionModeRow(.rulesBased, title: "Rules-based", description: "Include transactions automatically from category, vendor, or account rules.", recommended: false)
                    inclusionModeRow(.includeAll, title: "Include everything", description: "Include every transaction inside the date range.", recommended: false)
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))

            // Rules pickers (only when rules-based)
            if inclusionMode == .rulesBased {
                VStack(alignment: .leading, spacing: PPSpacing.lg) {
                    Text("Rules")
                        .font(.ppTitle3)
                        .foregroundColor(.ppTextPrimary(colorScheme))

                    if isLoadingOptions {
                        HStack { Spacer(); ProgressView().tint(.ppTextSecondary(colorScheme)); Spacer() }
                    } else {
                        multiSelectSection(
                            title: "Accounts",
                            items: accountOptions.map { ($0.id, "\($0.icon) \($0.name)") },
                            selected: $selectedAccountIds
                        )
                        multiSelectSection(
                            title: "Categories",
                            items: categoryOptions.map { ($0.id, "\($0.icon) \($0.name)") },
                            selected: $selectedCategoryIds
                        )
                        multiSelectSection(
                            title: "Vendors",
                            items: vendorOptions.map { ($0.id, $0.name) },
                            selected: $selectedVendorIds
                        )
                    }
                }
                .padding(PPSpacing.lg)
                .background(Color.ppCard(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
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
                    .foregroundColor(inclusionMode == mode ? .ppPrimary : .ppTextTertiary(colorScheme))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    HStack(spacing: PPSpacing.xs) {
                        Text(title)
                            .font(.ppHeadline)
                            .foregroundColor(.ppTextPrimary(colorScheme))
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
                        .foregroundColor(.ppTextSecondary(colorScheme))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(PPSpacing.md)
            .background(inclusionMode == mode ? Color.ppPrimary.opacity(0.06) : Color.ppSurface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(inclusionMode == mode ? Color.ppPrimary.opacity(0.4) : Color.ppBorder(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func multiSelectSection(title: String, items: [(UUID, String)], selected: Binding<Set<UUID>>) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack {
                Text(title)
                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
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
                    .font(.ppCallout).foregroundColor(.ppTextTertiary(colorScheme))
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
                                Text(label).font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
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

    // MARK: - Step 3: Caps

    private var step3View: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xl) {

            // Card 1 — Total Amount Cap
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                // Toggle header
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Toggle(isOn: $isTotalCapEnabled.animation(.easeInOut(duration: 0.2))) {
                        VStack(alignment: .leading, spacing: PPSpacing.xs) {
                            Text("Total Amount Cap")
                                .font(.ppTitle3)
                                .foregroundColor(.ppTextPrimary(colorScheme))
                            Text("Set a spending limit for the entire overlay.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextSecondary(colorScheme))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .ppPrimary))
                }

                // Currency text field, shown when enabled
                if isTotalCapEnabled {
                    HStack {
                        Text(currencySymbol)
                            .font(.ppBody)
                            .foregroundColor(.ppTextSecondary(colorScheme))
                        TextField("0.00", text: $totalCapText)
                            .font(.ppBody)
                            .foregroundColor(.ppTextPrimary)
                            .font(.ppAmount)
                            .foregroundColor(.ppTextSecondary)
                        TextField("0.00", text: $totalCapText)
                            .font(.ppAmount)
                            .foregroundColor(.ppTextPrimary)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, PPSpacing.lg)
                    .padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))

            // Card 2 — Per-Category Cap
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                // Toggle header
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Toggle(isOn: $isPerCategoryCapEnabled.animation(.easeInOut(duration: 0.2))) {
                        VStack(alignment: .leading, spacing: PPSpacing.xs) {
                            Text("Per-Category Cap")
                                .font(.ppTitle3)
                                .foregroundColor(.ppTextPrimary(colorScheme))
                            Text("Limit spending per category within this overlay.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextSecondary(colorScheme))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .ppPrimary))
                }

                // Category rows, shown when enabled
                if isPerCategoryCapEnabled {
                    if categoryOptions.isEmpty {
                        Text("No categories available.")
                            .font(.ppCallout)
                            .foregroundColor(.ppTextTertiary(colorScheme))
                            .transition(.opacity)
                    } else {
                        VStack(spacing: PPSpacing.xs) {
                            ForEach(categoryOptions) { category in
                                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                                    // Category row with checkmark toggle
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if categoryCapSelections.contains(category.id) {
                                                categoryCapSelections.remove(category.id)
                                                categoryCaps.removeValue(forKey: category.id)
                                            } else {
                                                categoryCapSelections.insert(category.id)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: PPSpacing.md) {
                                            Image(systemName: categoryCapSelections.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(categoryCapSelections.contains(category.id) ? .ppPrimary : .ppTextTertiary(colorScheme))

                                            Text("\(category.icon) \(category.name)")
                                                .font(.ppBody)
                                                .foregroundColor(.ppTextPrimary(colorScheme))

                                            Spacer()
                                        }
                                        .padding(.horizontal, PPSpacing.md)
                                        .padding(.vertical, PPSpacing.sm)
                                        .background(categoryCapSelections.contains(category.id) ? Color.ppPrimary.opacity(0.06) : Color.ppSurface(colorScheme))
                                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: PPRadius.md)
                                                .stroke(categoryCapSelections.contains(category.id) ? Color.ppPrimary.opacity(0.4) : Color.ppBorder(colorScheme), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    // Indented amount field when category is selected
                                    if categoryCapSelections.contains(category.id) {
                                        HStack {
                                            Spacer().frame(width: PPSpacing.xl)
                                            HStack {
                                                Text(currencySymbol)
                                                    .font(.ppCallout)
                                                    .foregroundColor(.ppTextSecondary)
                                                    .font(.ppAmount)
                                                    .foregroundColor(.ppTextSecondary)
                                                TextField("0.00", text: Binding(
                                                    get: { categoryCaps[category.id] ?? "" },
                                                    set: { categoryCaps[category.id] = $0 }
                                                ))
                                                .font(.ppCallout)
                                                .foregroundColor(.ppTextPrimary)
                                                .font(.ppAmount)
                                                .foregroundColor(.ppTextPrimary)
                                                .keyboardType(.decimalPad)
                                            }
                                            .padding(.horizontal, PPSpacing.md)
                                            .padding(.vertical, PPSpacing.sm)
                                            .background(Color.ppSurface(colorScheme))
                                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                                            .frame(maxWidth: .infinity)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
        }
    }

    // MARK: - Step 4: Review

    private var step4View: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {

            // Edit-mode warning
            if isEditMode {
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.ppAmber)
                        .font(.ppBody)
                    Text("Changing date range or inclusion mode updates which transactions may belong to this overlay.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextPrimary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(PPSpacing.md)
                .background(Color.ppAmber.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppAmber.opacity(0.3), lineWidth: 1))
            }

            // Summary card
            VStack(alignment: .leading, spacing: PPSpacing.md) {
                Text("Summary")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                Divider().background(Color.ppBorder(colorScheme))

                // Row 1: Name
                reviewRow(label: "Name") {
                    HStack(spacing: PPSpacing.xs) {
                        if let emoji = selectedEmoji {
                            Text(emoji).font(.ppBody)
                        }
                        Text(name.trimmingCharacters(in: .whitespaces))
                            .font(.ppBody)
                            .foregroundColor(.ppTextPrimary(colorScheme))
                    }
                }

                Divider().background(Color.ppBorder(colorScheme))

                // Row 2: Date Range
                reviewRow(label: "Date Range") {
                    Text(formatReviewDateRange())
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary(colorScheme))
                        .multilineTextAlignment(.trailing)
                }

                Divider().background(Color.ppBorder(colorScheme))

                // Row 3: Inclusion
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    reviewRow(label: "Inclusion") {
                        Text(inclusionModeLabel(inclusionMode))
                            .font(.ppBody)
                            .foregroundColor(.ppTextPrimary(colorScheme))
                    }
                    if inclusionMode == .rulesBased {
                        let accountCount = selectedAccountIds.count
                        let categoryCount = selectedCategoryIds.count
                        let vendorCount = selectedVendorIds.count
                        let parts = [
                            accountCount > 0 ? "\(accountCount) account\(accountCount == 1 ? "" : "s")" : nil,
                            categoryCount > 0 ? "\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")" : nil,
                            vendorCount > 0 ? "\(vendorCount) vendor\(vendorCount == 1 ? "" : "s")" : nil
                        ].compactMap { $0 }
                        if !parts.isEmpty {
                            Text(parts.joined(separator: ", "))
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary(colorScheme))
                                .padding(.leading, PPSpacing.sm)
                        }
                    }
                }

                Divider().background(Color.ppBorder(colorScheme))

                // Row 4: Total Cap
                reviewRow(label: "Total Cap") {
                    if isTotalCapEnabled, let cents = totalCapAmountCents {
                        Text(formatCentsForReview(cents))
                            .font(.ppBody)
                            .foregroundColor(.ppTextPrimary(colorScheme))
                    } else {
                        Text("None")
                            .font(.ppBody)
                            .foregroundColor(.ppTextTertiary(colorScheme))
                    }
                }

                // Row 5: Per-Category Caps (only if enabled and selections non-empty)
                if isPerCategoryCapEnabled && !categoryCapSelections.isEmpty {
                    Divider().background(Color.ppBorder(colorScheme))

                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text("Per-Category Caps")
                            .font(.ppCallout)
                            .fontWeight(.semibold)
                            .foregroundColor(.ppTextSecondary(colorScheme))

                        ForEach(categoryOptions.filter { categoryCapSelections.contains($0.id) }) { category in
                            HStack {
                                Text("\(category.icon) \(category.name)")
                                    .font(.ppBody)
                                    .foregroundColor(.ppTextPrimary(colorScheme))
                                Spacer()
                                if let text = categoryCaps[category.id],
                                   let value = Double(text.replacingOccurrences(of: ",", with: ".")) {
                                    Text(formatCentsForReview(Int64(value * 100)))
                                        .font(.ppBody)
                                        .foregroundColor(.ppTextPrimary(colorScheme))
                                } else {
                                    Text("—")
                                        .font(.ppBody)
                                        .foregroundColor(.ppTextTertiary(colorScheme))
                                }
                            }
                        }
                    }
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))

            // Submit error
            if let error = errorMessage {
                Text(error)
                    .font(.ppCallout)
                    .foregroundColor(.ppDestructive)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Review Helpers

    private func reviewRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.ppCallout)
                .fontWeight(.semibold)
                .foregroundColor(.ppTextSecondary(colorScheme))
            Spacer()
            content()
        }
    }

    private func formatReviewDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day.map { $0 + 1 } ?? 1
        return "\(startStr) – \(endStr) · \(days) day\(days == 1 ? "" : "s")"
    }

    private func inclusionModeLabel(_ mode: OverlayInclusionMode) -> String {
        switch mode {
        case .manual: return "Manual"
        case .rulesBased: return "Rules-based"
        case .includeAll: return "Include everything"
        }
    }

    private func formatCentsForReview(_ cents: Int64) -> String {
        formatCurrency(cents, code: appState.currencyCode)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: PPSpacing.md) {
            if currentStep > 0 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) { currentStep -= 1 }
                } label: {
                    HStack(spacing: PPSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.ppBody.weight(.semibold))
                    .foregroundColor(.ppTextSecondary(colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                }
            }

            if currentStep < 3 {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
                } label: {
                    HStack(spacing: PPSpacing.sm) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.ppBody.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(nextButtonDisabled ? Color.ppPrimary.opacity(0.4) : Color.ppPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                }
                .disabled(nextButtonDisabled)
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await submit() }
                } label: {
                    HStack(spacing: PPSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                            Text(isEditMode ? "Save Changes" : "Create Overlay")
                        }
                    }
                    .font(.ppBody.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(isLoading ? Color.ppPrimary.opacity(0.4) : Color.ppPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                }
                .disabled(isLoading)
            }
        }
    }

    private var nextButtonDisabled: Bool {
        switch currentStep {
        case 0: return !step1Valid
        case 1:
            if inclusionMode == .rulesBased {
                return selectedAccountIds.isEmpty && selectedCategoryIds.isEmpty && selectedVendorIds.isEmpty
            }
            return false
        default: return false
        }
    }

    // MARK: - Submit

    @MainActor private func submit() async {
        isLoading = true
        errorMessage = nil

        let rules = OverlayRules(
            accountIds: inclusionMode == .rulesBased ? Array(selectedAccountIds) : [],
            categoryIds: inclusionMode == .rulesBased ? Array(selectedCategoryIds) : [],
            vendorIds: inclusionMode == .rulesBased ? Array(selectedVendorIds) : []
        )
        let req = OverlayRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedEmoji,
            startDate: DateFormatter.apiDate.string(from: startDate),
            endDate: DateFormatter.apiDate.string(from: endDate),
            inclusionMode: inclusionMode.rawValue,
            totalCapAmount: isTotalCapEnabled ? totalCapAmountCents : nil,
            rules: rules,
            categoryCaps: buildCategoryCaps()
        )

        do {
            if let existing = overlay {
                let _: OverlayItem = try await appState.apiClient.request(.updateOverlay(existing.id), body: req)
            } else {
                let _: OverlayItem = try await appState.apiClient.request(.createOverlay, body: req)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to save overlay.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isLoading = false
    }

    private func buildCategoryCaps() -> [OverlayCategoryCap] {
        guard isPerCategoryCapEnabled else { return [] }
        return categoryCapSelections.compactMap { id -> OverlayCategoryCap? in
            guard let text = categoryCaps[id] else { return nil }
            let cleaned = text.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(cleaned), value > 0 else { return nil }
            return OverlayCategoryCap(categoryId: id, capAmount: Int64(value * 100))
        }
    }

    // MARK: - Load Options

    @MainActor private func loadOptions() async {
        isLoadingOptions = true
        defer { isLoadingOptions = false }

        async let accountsFetch: [AccountOption] = (try? appState.apiClient.request(.accountOptions)) ?? []
        async let categoriesFetch: [CategoryOption] = (try? appState.apiClient.request(.categoryOptions)) ?? []
        async let vendorsFetch: PaginatedResponse<VendorOption> = (try? appState.apiClient.request(.vendors)) ?? PaginatedResponse(data: [], nextCursor: nil)

        let (accounts, categories, vendorsPage) = await (accountsFetch, categoriesFetch, vendorsFetch)
        accountOptions = accounts
        categoryOptions = categories
        vendorOptions = vendorsPage.data
    }

    // MARK: - Prefill (Edit Mode)

    private func prefill(from item: OverlayItem) {
        name = item.name
        selectedEmoji = item.icon

        if let start = DateFormatter.apiDate.date(from: item.startDate) {
            startDate = start
        }
        if let end = DateFormatter.apiDate.date(from: item.endDate) {
            endDate = end
        }

        inclusionMode = OverlayInclusionMode(rawValue: item.inclusionMode) ?? .includeAll

        // Restore rules-based filter selections
        if let rules = item.rules {
            selectedAccountIds = Set(rules.accountIds)
            selectedCategoryIds = Set(rules.categoryIds)
            selectedVendorIds = Set(rules.vendorIds)
        }

        // Restore total cap
        if let cap = item.totalCapAmount {
            isTotalCapEnabled = true
            totalCapText = String(format: "%.2f", Double(cap) / 100.0)
        }

        // Restore per-category caps
        if let caps = item.categoryCaps, !caps.isEmpty {
            isPerCategoryCapEnabled = true
            for cap in caps {
                categoryCapSelections.insert(cap.categoryId)
                categoryCaps[cap.categoryId] = String(format: "%.2f", Double(cap.capAmount) / 100.0)
            }
        }
    }
}
