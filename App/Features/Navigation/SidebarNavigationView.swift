import SwiftUI

/// iPad sidebar navigation using NavigationSplitView.
/// Shows all sections in a sidebar with detail area on the right.
struct SidebarNavigationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme

    enum Destination: String, Hashable, CaseIterable {
        case dashboard
        case transactions
        case accounts
        case periods
        case categories
        case targets
        case subscriptions
        case vendors
        case settings
    }

    @State private var selection: Destination? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Returns a list row background with a leading accent line for the selected item.
    private func rowBackground(for destination: Destination) -> some View {
        let isSelected = selection == destination
        return HStack(spacing: 0) {
            // Accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? theme.primary : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 4)

            // Background fill
            Rectangle()
                .fill(isSelected ? theme.primary.opacity(0.08) : Color.clear)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailView
        }
        .tint(theme.primary)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            // Period selector at top
            Section {
                PeriodSelectorSidebarRow()
            }

            // Overview
            Section(String(localized: "sidebar.overview")) {
                Label(String(localized: "tab.dashboard"), systemImage: "house.fill")
                    .tag(Destination.dashboard)
                    .listRowBackground(rowBackground(for: .dashboard))
                Label(String(localized: "tab.transactions"), systemImage: "arrow.left.arrow.right")
                    .tag(Destination.transactions)
                    .listRowBackground(rowBackground(for: .transactions))
                Label(String(localized: "tab.accounts"), systemImage: "creditcard.fill")
                    .tag(Destination.accounts)
                    .listRowBackground(rowBackground(for: .accounts))
            }

            // Planning
            Section(String(localized: "more.planning")) {
                Label(String(localized: "more.periods"), systemImage: "calendar")
                    .tag(Destination.periods)
                    .listRowBackground(rowBackground(for: .periods))
                Label(String(localized: "more.categories"), systemImage: "tag")
                    .tag(Destination.categories)
                    .listRowBackground(rowBackground(for: .categories))
                Label(String(localized: "more.targets"), systemImage: "chart.pie")
                    .tag(Destination.targets)
                    .listRowBackground(rowBackground(for: .targets))
            }

            // Tracking
            Section(String(localized: "more.tracking")) {
                Label(String(localized: "more.subscriptions"), systemImage: "repeat")
                    .tag(Destination.subscriptions)
                    .listRowBackground(rowBackground(for: .subscriptions))
                Label(String(localized: "more.vendors"), systemImage: "storefront")
                    .tag(Destination.vendors)
                    .listRowBackground(rowBackground(for: .vendors))
            }

            // App
            Section(String(localized: "more.app")) {
                Label(String(localized: "more.settings"), systemImage: "gearshape")
                    .tag(Destination.settings)
                    .listRowBackground(rowBackground(for: .settings))
            }

            // Logout
            Section {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await appState.logout() }
                } label: {
                    Label(String(localized: "more.logout"), systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.sharedDestructive)
                }
            }
        }
        .navigationTitle("PiggyPulse")
        .listStyle(.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 600
            Group {
                switch selection {
                case .dashboard:
                    DashboardView().environmentObject(appState)
                case .transactions:
                    NavigationStack {
                        TransactionsView().environmentObject(appState)
                    }
                case .accounts:
                    NavigationStack {
                AccountsView().environmentObject(appState)
            }
        case .periods:
            NavigationStack {
                PeriodsView().environmentObject(appState)
            }
        case .categories:
            NavigationStack {
                CategoriesView().environmentObject(appState)
            }
        case .targets:
            NavigationStack {
                BudgetPlanView().environmentObject(appState)
            }
        case .subscriptions:
            NavigationStack {
                SubscriptionsView().environmentObject(appState)
            }
        case .vendors:
            NavigationStack {
                VendorsView().environmentObject(appState)
            }
        case .settings:
            NavigationStack {
                SettingsView().environmentObject(appState)
            }
        case nil:
            Text(String(localized: "sidebar.selectSection"))
                .font(.ppTitle3)
                .foregroundColor(.ppTextTertiary)
                }
            }
            .environment(\.isWideLayout, wide)
        }
    }
}

// MARK: - Period Selector for Sidebar

/// Compact period selector row designed for the sidebar.
struct PeriodSelectorSidebarRow: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @State private var showPicker = false
    @State private var periods: [BudgetPeriod] = []

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: PPSpacing.sm) {
                Image(systemName: "calendar")
                    .foregroundColor(theme.primary)

                if let period = appState.selectedPeriod {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(period.name)
                            .font(.ppCallout).fontWeight(.semibold)
                            .foregroundColor(.ppTextPrimary)
                        Text(period.dateRangeText)
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                } else {
                    Text(String(localized: "periodSelector.noneSelected"))
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
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
                let repo = PeriodRepository(apiClient: appState.apiClient)
                periods = (try? await repo.fetchPeriods()) ?? []
                if appState.selectedPeriod == nil {
                    appState.selectedPeriod = periods.first(where: { $0.periodStatus == .active }) ?? periods.first
                }
            }
        }
    }
}
