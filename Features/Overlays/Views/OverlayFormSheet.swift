import SwiftUI

struct OverlayFormSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    var overlay: OverlayItem?
    var onSaved: () -> Void

    // MARK: - Step State

    @State private var currentStep = 0

    // Step 1 — Basics
    @State private var name: String = ""
    @State private var selectedEmoji: String? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    // Step 2 — Inclusion
    @State private var inclusionMode: OverlayInclusionMode = .includeAll
    @State private var selectedAccountIds: Set<UUID> = []
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var selectedVendorIds: Set<UUID> = []

    // Step 3 — Caps
    @State private var totalCapText: String = ""
    @State private var categoryCaps: [UUID: String] = [:]

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

    private var step1Valid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
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
                Color.ppBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.top, PPSpacing.lg)
                        .padding(.bottom, PPSpacing.md)

                    Divider().background(Color.ppBorder)

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
                    }

                    Divider().background(Color.ppBorder)
                    navigationButtons
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.vertical, PPSpacing.lg)
                }
            }
            .navigationTitle(isEditMode ? "Edit Overlay" : "New Overlay")
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
                                index > currentStep ? Color.ppBorder : Color.clear,
                                lineWidth: 1.5
                            )
                        )
                        .frame(width: 12, height: 12)
                    Text(labels[index])
                        .font(.ppCaption)
                        .foregroundColor(index == currentStep ? .ppPrimary : .ppTextTertiary)
                }
                if index < 3 {
                    Rectangle()
                        .fill(index < currentStep ? Color.ppPrimary.opacity(0.5) : Color.ppBorder)
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
                    .foregroundColor(.ppTextPrimary)

                // Name field
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("e.g. Summer Vacation Budget", text: $name)
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                        .padding(.horizontal, PPSpacing.lg)
                        .padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }

                // Emoji picker
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Icon (optional)")
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    EmojiPickerGrid(selectedEmoji: $selectedEmoji)
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

            // Date range card
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Date Range")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                // Start Date
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Start Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(.ppPrimary)
                }

                // End Date
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("End Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    DatePicker(
                        "",
                        selection: $endDate,
                        in: minEndDate...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(.ppPrimary)
                }

                // Disclaimer
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                    Text("The overlay will track transactions that fall within this date range. Dates are inclusive.")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
        }
    }

    // MARK: - Step 2: Inclusion (stub)

    private var step2View: some View {
        Text("Step 2: Inclusion Rules — coming soon")
            .font(.ppBody)
            .foregroundColor(.ppTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, PPSpacing.xl)
    }

    // MARK: - Step 3: Caps (stub)

    private var step3View: some View {
        Text("Step 3: Spending Caps — coming soon")
            .font(.ppBody)
            .foregroundColor(.ppTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, PPSpacing.xl)
    }

    // MARK: - Step 4: Review (stub)

    private var step4View: some View {
        Text("Step 4: Review — coming soon")
            .font(.ppBody)
            .foregroundColor(.ppTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, PPSpacing.xl)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: PPSpacing.md) {
            if currentStep > 0 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: PPSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.ppBody.weight(.semibold))
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation { currentStep += 1 }
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
        default: return false
        }
    }

    // MARK: - Submit

    private func submit() async {
        isLoading = true
        errorMessage = nil

        let req = OverlayRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedEmoji,
            startDate: DateFormatter.apiDate.string(from: startDate),
            endDate: DateFormatter.apiDate.string(from: endDate),
            inclusionMode: inclusionMode.rawValue,
            accountIds: selectedAccountIds.isEmpty ? nil : Array(selectedAccountIds),
            categoryIds: selectedCategoryIds.isEmpty ? nil : Array(selectedCategoryIds),
            vendorIds: selectedVendorIds.isEmpty ? nil : Array(selectedVendorIds),
            totalCapAmount: totalCapAmountCents,
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

    private func buildCategoryCaps() -> [CategoryCap]? {
        let caps = categoryCaps.compactMap { (id, text) -> CategoryCap? in
            let cleaned = text.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(cleaned), value > 0 else { return nil }
            return CategoryCap(categoryId: id, amount: Int64(value * 100))
        }
        return caps.isEmpty ? nil : caps
    }

    // MARK: - Load Options

    private func loadOptions() async {
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
    }
}
