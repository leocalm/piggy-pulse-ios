import SwiftUI
import TipKit

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel: DashboardV2ViewModel
    @State private var showAddTransaction = false
    @State private var showAddWidget = false
    @State private var layoutVersion = 0 // Bump to force re-render after widget changes

    private let dashboardTip = DashboardTip()

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: DashboardV2ViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "tab.dashboard"), showTitle: false)
                    .navigationTitle(String(localized: "tab.dashboard"))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: PPSpacing.xl) {
                        TipView(dashboardTip)

                        if viewModel.isLoading {
                            loadingState
                        } else if let error = viewModel.errorMessage {
                            errorState(error)
                        } else {
                            ForEach(viewModel.layout.visibleWidgets, id: \.self) { widgetId in
                                renderWidget(widgetId)
                            }
                            .id(layoutVersion)
                        }
                    }
                    .padding(PPSpacing.lg)
                }
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
                    AddTransactionSheet(onCreated: {})
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showAddWidget, onDismiss: {
                    layoutVersion += 1 // Force re-render after widget customization
                }) {
                    AddWidgetSheet(layout: viewModel.layout)
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
                NetPositionCard(data: data, currencyCode: appState.currencyCode)
            }
        case "cash_flow":
            if let data = viewModel.cashFlow {
                CashFlowCard(data: data, currencyCode: appState.currencyCode)
            }
        case "recent_transactions":
            if let data = viewModel.recentTransactions {
                RecentTransactionsCard(transactions: data, currencyCode: appState.currencyCode)
            }
        case "spending_trend":
            if let data = viewModel.spendingTrend {
                SpendingTrendCard(data: data, currencyCode: appState.currencyCode)
            }
        case "top_vendors":
            if let data = viewModel.topVendors {
                TopVendorsCard(vendors: data, currencyCode: appState.currencyCode)
            }
        case "variable_categories":
            if let data = viewModel.variableCategories {
                VariableCategoriesCard(data: data, currencyCode: appState.currencyCode)
            }
        case "fixed_categories":
            if let data = viewModel.fixedCategories {
                FixedCategoriesCard(data: data, currencyCode: appState.currencyCode)
            }
        case "subscriptions":
            if let data = viewModel.subscriptions {
                SubscriptionsCard(data: data, currencyCode: appState.currencyCode)
            }
        default:
            EmptyView()
        }
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
                if let periodId = appState.selectedPeriod?.id {
                    Task { await viewModel.load(periodId: periodId) }
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "dashboard.visibleWidgets")) {
                    ForEach(layout.visibleWidgets, id: \.self) { id in
                        if let def = widgetDefinitions.first(where: { $0.id == id }) {
                            HStack {
                                Image(systemName: def.sfSymbol)
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)
                                Text(def.name)
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
                    }
                    .onMove { source, destination in
                        layout.moveWidget(from: source, to: destination)
                    }
                }

                let hiddenIds = widgetDefinitions.filter { layout.hiddenWidgets.contains($0.id) }
                if !hiddenIds.isEmpty {
                    Section(String(localized: "dashboard.hiddenWidgets")) {
                        ForEach(hiddenIds) { def in
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
