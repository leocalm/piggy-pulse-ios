import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: DashboardViewModel

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.xl) {
                    if viewModel.isLoading {
                        loadingState
                    } else if let error = viewModel.errorMessage {
                        errorState(error)
                    } else {
                        ForEach(viewModel.layout.visibleCards) { card in
                            cardView(for: card)
                        }
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground(colorScheme))
            .task(id: appState.selectedPeriod?.id) {
                if let periodId = appState.selectedPeriod?.id {
                    await viewModel.load(periodId: periodId)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DashboardCustomizationView(viewModel: viewModel)) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
    }

    // MARK: - Card Dispatch

    @ViewBuilder
    private func cardView(for config: DashboardCardConfig) -> some View {
        switch config.cardType {
        case .currentPeriod:
            if let burnIn = viewModel.burnIn, let progress = viewModel.progress {
                CurrentPeriodCardView(burnIn: burnIn, progress: progress)
            }
        case .budgetStability:
            if let stability = viewModel.stability, stability.totalClosedPeriods > 0 {
                BudgetStabilityCardView(stability: stability)
            }
        case .netPosition:
            if let net = viewModel.netPosition {
                NetPositionCardView(net: net)
            }
        case .recentTransactions:
            RecentTransactionsCardView(transactions: viewModel.recentTransactions)
        case .topCategories:
            TopCategoriesCardView(categories: viewModel.topCategories)
        case .budgetPerDay:
            if let burnIn = viewModel.burnIn, let progress = viewModel.progress {
                BudgetPerDayCardView(burnIn: burnIn, progress: progress)
            }
        case .remainingBudget:
            if let burnIn = viewModel.burnIn, let progress = viewModel.progress {
                RemainingBudgetCardView(burnIn: burnIn, progress: progress)
            }
        case .balanceOverTime:
            BalanceOverTimeCardView(dataPoints: viewModel.balanceOverTime)
        case .accountSummary:
            if let entityId = config.entityId,
               let account = viewModel.accountSnapshots[entityId] {
                AccountSummaryCardView(account: account)
            }
        case .categoryBreakdown:
            if let entityId = config.entityId,
               let items = viewModel.categoryBreakdowns[entityId] {
                CategoryBreakdownCardView(
                    categoryName: viewModel.entityNames[entityId] ?? "Category",
                    spending: items
                )
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: PPSpacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .fill(Color.ppCard(colorScheme))
                    .frame(height: 160)
            }
        }
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack(spacing: PPSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.ppAmber)
            Text(message)
                .font(.ppBody)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .multilineTextAlignment(.center)
            Button("Retry") {
                if let periodId = appState.selectedPeriod?.id {
                    Task { await viewModel.load(periodId: periodId) }
                }
            }
            .font(.ppHeadline)
            .foregroundColor(.ppPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PPSpacing.xxxl)
    }
}
