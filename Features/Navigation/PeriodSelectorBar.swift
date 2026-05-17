import SwiftUI

// MARK: - Option A: Improved Tab Bar Sidecar

/// Period selector in the tab bar bottom accessory.
/// Improved with a "PERIOD" label and chevron to signal interactivity.
struct PeriodSelectorBar: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @State private var periods: [BudgetPeriod] = []
    @State private var showPicker = false
    @State private var isLoading = true
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPicker = true
        } label: {
            HStack(spacing: PPSpacing.sm) {
                // Leading label to clarify what this is
                Text(String(localized: "periodSelector.label"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.ppTextTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Divider()
                    .frame(height: 16)

                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundColor(theme.primary)

                if isLoading {
                    ProgressView()
                        .tint(.ppTextSecondary)
                        .scaleEffect(0.7)
                } else if let period = appState.selectedPeriod {
                    Text(period.name)
                        .font(.ppCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    if placement == .expanded {
                        Text(period.dateRangeText)
                            .font(.system(size: 10))
                            .foregroundColor(.ppTextSecondary)
                    }

                    statusDot(period.periodStatus)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.ppTextTertiary)
                } else {
                    Text(String(localized: "periodSelector.noneSelected"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.ppTextTertiary)
                }
            }
            .padding(.horizontal, PPSpacing.lg)
            .padding(.vertical, PPSpacing.sm)
        }
        .sheet(isPresented: $showPicker) {
            PeriodPickerSheet(
                periods: periods,
                selectedPeriod: appState.selectedPeriod,
                onSelect: { period in
                    appState.selectedPeriod = period
                    showPicker = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task(id: appState.isAuthenticated) {
            if appState.isAuthenticated {
                await loadPeriods()
            }
        }
    }

    private func loadPeriods() async {
        guard periods.isEmpty else { isLoading = false; return }
        if let profile = appState.screenshotConfiguration?.profile {
            periods = profile.periods
            if appState.selectedPeriod == nil {
                appState.selectedPeriod = profile.activePeriod
            }
            isLoading = false
            return
        }

        isLoading = true
        let repo = PeriodRepository(apiClient: appState.apiClient)
        do {
            let fetched = try await repo.fetchPeriods()
            periods = fetched
            if appState.selectedPeriod == nil {
                appState.selectedPeriod = fetched.first(where: { $0.periodStatus == .active })
                    ?? fetched.first
            }
        } catch {}
        isLoading = false
    }

    private func statusDot(_ status: PeriodStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 6, height: 6)
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return theme.primary
        case .ended: return .ppTextTertiary
        case .upcoming: return theme.secondary
        case .unknown: return .ppTextTertiary
        }
    }
}

// MARK: - Option B: Navigation Bar Title Picker

/// Period selector that renders as a toolbar principal item.
/// Use via `.toolbar { PeriodSelectorToolbar() }` on each screen's NavigationStack.
struct PeriodSelectorToolbar: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) var theme

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            PeriodSelectorTitleButton()
        }
    }
}

/// Compact button designed to sit in the navigation bar title area.
/// Shows period name + status dot + chevron. Taps open the period picker.
struct PeriodSelectorTitleButton: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @State private var showPicker = false
    @State private var periods: [BudgetPeriod] = []

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPicker = true
        } label: {
            HStack(spacing: PPSpacing.xs) {
                if let period = appState.selectedPeriod {
                    statusDot(period.periodStatus)

                    Text(period.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.ppTextPrimary)
                        .lineLimit(1)
                } else {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 13))
                        .foregroundColor(.ppTextSecondary)

                    Text(String(localized: "periodSelector.noneSelected"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ppTextSecondary)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.ppTextTertiary)
            }
        }
        .sheet(isPresented: $showPicker) {
            PeriodPickerSheet(
                periods: periods,
                selectedPeriod: appState.selectedPeriod,
                onSelect: { period in
                    appState.selectedPeriod = period
                    showPicker = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task(id: appState.isAuthenticated) {
            if appState.isAuthenticated {
                await loadPeriods()
            }
        }
    }

    private func loadPeriods() async {
        guard periods.isEmpty else { return }
        if let profile = appState.screenshotConfiguration?.profile {
            periods = profile.periods
            return
        }

        let repo = PeriodRepository(apiClient: appState.apiClient)
        periods = (try? await repo.fetchPeriods()) ?? []
    }

    private func statusDot(_ status: PeriodStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 7, height: 7)
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return theme.primary
        case .ended: return .ppTextTertiary
        case .upcoming: return theme.secondary
        case .unknown: return .ppTextTertiary
        }
    }
}

// MARK: - Shared Period Picker Sheet

struct PeriodPickerSheet: View {
    @Environment(\.themeManager) private var theme
    let periods: [BudgetPeriod]
    let selectedPeriod: BudgetPeriod?
    let onSelect: (BudgetPeriod) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PPSpacing.sm) {
                    ForEach(periods) { period in
                        Button {
                            onSelect(period)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(period.name)
                                        .font(.ppHeadline)
                                        .foregroundColor(.ppTextPrimary)

                                    HStack(spacing: 4) {
                                        Text(period.dateRangeText)
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextSecondary)
                                        Text("·")
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextTertiary)
                                        Text(period.statusText)
                                            .font(.ppCaption)
                                            .foregroundColor(statusColor(period.periodStatus))
                                    }
                                }

                                Spacer()

                                if period.id == selectedPeriod?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .padding(PPSpacing.lg)
                            .background(
                                period.id == selectedPeriod?.id
                                    ? theme.primary.opacity(0.1)
                                    : Color.ppCard
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: PPRadius.md)
                                    .stroke(
                                        period.id == selectedPeriod?.id
                                            ? theme.primary.opacity(0.3)
                                            : Color.ppBorder,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .navigationTitle(String(localized: "periodSelector.selectPeriod"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return theme.primary
        case .ended: return .ppTextTertiary
        case .upcoming: return theme.secondary
        case .unknown: return .ppTextTertiary
        }
    }
}
