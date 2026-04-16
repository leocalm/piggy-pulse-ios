import SwiftUI
import TipKit

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = DashboardV2ViewModel()
    @State private var showAddTransaction = false
    @State private var showAddWidget = false
    @State private var layoutVersion = 0 // Bump to force re-render after widget changes

    private let dashboardTip = DashboardTip()

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "tab.dashboard"), showTitle: false)
                    .navigationTitle(String(localized: "tab.dashboard"))
            } else {
                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: PPSpacing.xl) {
                            TipView(dashboardTip)

                            if viewModel.isLoading {
                                loadingState
                            } else if let error = viewModel.errorMessage {
                                errorState(error)
                            } else {
                                AdaptiveWidgetGrid(
                                    widgets: viewModel.layout.visibleWidgets,
                                    useGrid: geo.size.width >= 700
                                ) { widgetId in
                                    renderWidget(widgetId)
                                }
                                .id(layoutVersion)
                            }
                        }
                        .padding(PPSpacing.lg)
                    }
                    .refreshable {
                    viewModel.configure(dataStore: appState.dataStore)
                    guard let period = appState.selectedPeriod else { return }
                    appState.dataStore.clear()
                    let vm = viewModel
                    await Task { @MainActor in
                        await vm.load(period: period)
                    }.value
                }
                } // GeometryReader
                .background(Color.ppBackground)
                .task(id: appState.selectedPeriod?.id) {
                    viewModel.configure(dataStore: appState.dataStore)
                    if let period = appState.selectedPeriod {
                        await viewModel.load(period: period)
                    }
                }
                .navigationTitle(String(localized: "tab.dashboard"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showAddTransaction = true
                            } label: {
                                Label(String(localized: "dashboard.addTransaction"), systemImage: "plus.circle")
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showAddWidget = true
                            } label: {
                                Label(String(localized: "dashboard.customize"), systemImage: "slider.horizontal.3")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 17))
                        }
                    }
                }
                .sheet(isPresented: $showAddTransaction) {
                    AddTransactionSheet(onCreated: {
                        if let period = appState.selectedPeriod {
                            appState.dataStore.clear()
                            Task { await viewModel.load(period: period) }
                        }
                    })
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showAddWidget, onDismiss: {
                    layoutVersion += 1 // Force re-render after widget customization
                }) {
                    AddWidgetSheet(layout: viewModel.layout, accounts: viewModel.accounts ?? [])
                }
            }
        }
    }

    // MARK: - Widget Renderer

    @ViewBuilder
    private func renderWidget(_ id: String) -> some View {
        switch id {
        case "getting_started":
            GettingStartedCard()
        case "current_period":
            if let data = viewModel.currentPeriod {
                CurrentPeriodCard(data: data, currencyCode: appState.currencyCode)
            }
        case "net_position":
            if let data = viewModel.netPosition {
                NetPositionCard(data: data, accounts: viewModel.accounts ?? [], currencyCode: appState.currencyCode)
            }
        case "cash_flow":
            if let data = viewModel.cashFlow {
                CashFlowCard(data: data, currencyCode: appState.currencyCode)
            }
        case "recent_transactions":
            RecentTransactionsCard(transactions: viewModel.recentTransactions ?? [], currencyCode: appState.currencyCode)
        case "spending_trend":
            SpendingTrendCard(
                data: viewModel.spendingTrend ?? DashboardSpendingTrend(periods: [], periodAverage: 0),
                currencyCode: appState.currencyCode
            )
        case "top_vendors":
            TopVendorsCard(vendors: viewModel.topVendors ?? [], currencyCode: appState.currencyCode)
        case "variable_categories":
            VariableCategoriesCard(
                data: viewModel.variableCategories ?? DashboardVariableCategories(totalBudgeted: 0, totalSpent: 0, categories: []),
                currencyCode: appState.currencyCode
            )
        case "fixed_categories":
            FixedCategoriesCard(
                data: viewModel.fixedCategories ?? DashboardFixedCategories(totalBudgeted: 0, totalPaid: 0, categories: []),
                currencyCode: appState.currencyCode
            )
        case "subscriptions":
            SubscriptionsCard(
                data: viewModel.subscriptions ?? DashboardSubscriptions(activeCount: 0, monthlyTotal: 0, yearlyTotal: 0, subscriptions: []),
                currencyCode: appState.currencyCode
            )
        default:
            // Account cards: "account:{uuid}"
            if id.hasPrefix("account:"), let accountId = UUID(uuidString: String(id.dropFirst("account:".count))) {
                if let account = viewModel.accounts?.first(where: { $0.id == accountId }) {
                    accountCard(account)
                }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Account Card

    private func accountCard(_ account: AccountListItem) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            // Header: name + type badge
            HStack {
                Text(account.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                Spacer()
                Text(account.type.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, PPSpacing.sm)
                    .padding(.vertical, PPSpacing.xs)
                    .background(theme.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            }

            // Balance
            Text(formatCurrency(account.currentBalance, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary)

            // Period change
            let prefix = account.netChangeThisPeriod >= 0 ? "+" : ""
            Text("\(prefix)\(formatCurrency(account.netChangeThisPeriod, code: appState.currencyCode)) \(String(localized: "widget.netPosition.thisPeriod"))")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Type-specific info rows
            if account.type == "Allowance" {
                VStack(spacing: 0) {
                    infoRow(String(localized: "account.card.availableToSpend"), value: formatCurrency(max(account.currentBalance, 0), code: appState.currencyCode))
                    Divider().background(Color.ppBorder)
                    infoRow(String(localized: "account.card.nextTopUp"), value: account.nextTransfer.map { formatDateString($0) } ?? "—")
                    Divider().background(Color.ppBorder)
                    infoRow(String(localized: "account.card.balanceAfterTopUp"), value: formatCurrency(account.balanceAfterNextTransfer ?? account.currentBalance, code: appState.currencyCode))
                    Divider().background(Color.ppBorder)
                    infoRow(String(localized: "account.card.spentThisCycle"), value: formatCurrency(abs(account.netChangeThisPeriod), code: appState.currencyCode))
                }
                .background(Color.ppElevated)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            } else {
                // Standard stats: transactions + avg daily balance or limit
                HStack(spacing: PPSpacing.md) {
                    statBox(String(localized: "account.card.transactions"), value: "\(account.numberOfTransactions)")

                    if account.type == "CreditCard" {
                        statBox(String(localized: "account.card.creditLimit"), value: formatCurrency(Int64(account.spendLimit ?? 0), code: appState.currencyCode))
                    } else {
                        statBox(String(localized: "account.card.avgDailyBalance"), value: formatCurrency(account.currentBalance, code: appState.currencyCode))
                    }
                }
            }
        }
        .dashboardCard()
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ppCaption)
                .foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value)
                .font(.ppCallout)
                .fontDesign(.monospaced)
                .foregroundColor(.ppTextPrimary)
        }
        .padding(.horizontal, PPSpacing.md)
        .padding(.vertical, PPSpacing.sm)
    }

    private func statBox(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.ppTextTertiary)
                .tracking(0.5)
            Text(value)
                .font(.ppHeadline)
                .foregroundColor(.ppTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.sm)
        .background(Color.ppElevated)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: PPSpacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .fill(Color.ppCard)
                    .frame(height: 160)
                    .shimmering()
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: PPSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(theme.secondary)
            Text(message)
                .font(.ppBody)
                .foregroundColor(.ppTextSecondary)
                .multilineTextAlignment(.center)
            Button(String(localized: "common.retry")) {
                if let period = appState.selectedPeriod {
                    Task { await viewModel.load(period: period) }
                }
            }
            .font(.ppHeadline)
            .foregroundColor(theme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PPSpacing.xxxl)
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmering() -> some View {
        self.redacted(reason: .placeholder)
    }
}

// MARK: - Add Widget Sheet

struct AddWidgetSheet: View {
    let layout: DashboardLayout
    let accounts: [AccountListItem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    private var accountMap: [String: AccountListItem] {
        Dictionary(uniqueKeysWithValues: accounts.filter { $0.status == "active" }.map { ("account:\($0.id.uuidString)", $0) })
    }

    private func widgetLabel(for id: String) -> (icon: String, name: String) {
        if let def = widgetDefinitions.first(where: { $0.id == id }) {
            return (def.sfSymbol, def.name)
        } else if id.hasPrefix("account:"), let account = accountMap[id] {
            return ("creditcard", account.name)
        }
        return ("questionmark.circle", id)
    }

    var body: some View {
        NavigationStack {
            List {
                // Visible widgets (both standard + account cards, interleaved)
                Section(String(localized: "dashboard.visibleWidgets")) {
                    ForEach(layout.visibleWidgets, id: \.self) { id in
                        let info = widgetLabel(for: id)
                        HStack {
                            Image(systemName: info.icon)
                                .foregroundColor(theme.primary)
                                .frame(width: 24)
                            Text(info.name)
                                .font(.ppBody)
                            Spacer()
                            Button {
                                layout.removeWidget(id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.sharedDestructive)
                            }
                        }
                    }
                    .onMove { source, destination in
                        layout.moveWidget(from: source, to: destination)
                    }
                }

                // Hidden standard widgets
                let hiddenDefs = widgetDefinitions.filter { layout.hiddenWidgets.contains($0.id) }
                if !hiddenDefs.isEmpty {
                    Section(String(localized: "dashboard.hiddenWidgets")) {
                        ForEach(hiddenDefs) { def in
                            HStack {
                                Image(systemName: def.sfSymbol)
                                    .foregroundColor(.ppTextTertiary)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(def.name).font(.ppBody)
                                    Text(def.description).font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                                Spacer()
                                Button {
                                    layout.addWidget(def.id)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                        }
                    }
                }

                // Hidden account cards (not yet added to dashboard)
                let hiddenAccounts = accounts.filter { $0.status == "active" && !layout.visibleWidgets.contains("account:\($0.id.uuidString)") }
                if !hiddenAccounts.isEmpty {
                    Section(String(localized: "dashboard.accountCards")) {
                        ForEach(hiddenAccounts) { account in
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.ppTextTertiary)
                                    .frame(width: 24)
                                Text(account.name).font(.ppBody)
                                Spacer()
                                Button {
                                    layout.addWidget("account:\(account.id.uuidString)")
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "dashboard.customize"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
