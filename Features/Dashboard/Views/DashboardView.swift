import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: DashboardViewModel
    @State private var showAddTransaction = false

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
                        // Current Period card
                        if let burnIn = viewModel.burnIn, let progress = viewModel.progress {
                            currentPeriodCard(burnIn: burnIn, progress: progress)
                        }
                        
                        // Net Position card
                        if let net = viewModel.netPosition {
                            netPositionCard(net: net)
                        }
                        
                        // Spending Consistency card
                        if let stability = viewModel.stability, stability.totalClosedPeriods > 0 {
                            stabilityCard(stability: stability)
                        }
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .task(id: appState.selectedPeriod?.id) {
                if let periodId = appState.selectedPeriod?.id {
                    await viewModel.load(periodId: periodId)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAddTransaction = true
                    } label: {
                        Image("custom.arrow.left.arrow.right.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionSheet(onCreated: {})
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: PPSpacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .fill(Color.ppCard)
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
                .foregroundColor(.ppTextSecondary)
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

    // MARK: - Current Period Card

    private func currentPeriodCard(burnIn: MonthlyBurnIn, progress: MonthProgress) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("CURRENT PERIOD")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            // Spent amount
            Text(formatCurrency(burnIn.spentBudget, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary)

            Text("of \(formatCurrency(burnIn.totalBudget, code: appState.currencyCode))")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Remaining info
            Text("\(progress.remainingDays) days remaining. \(formatCurrency(burnIn.remainingBudget, code: appState.currencyCode)) remaining in this period.")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppPrimary)
                        .frame(width: geo.size.width * min(burnIn.spentPercentage, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            // Projected spend
            let projectedSpend = projectedSpendAmount(burnIn: burnIn, progress: progress)
            Text("Projected spend at current pace: \(formatCurrency(projectedSpend, code: appState.currencyCode))")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Spending Consistency Card

    private func stabilityCard(stability: BudgetStability) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("SPENDING CONSISTENCY")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text("\(stability.withinTolerancePercentage)%")
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary)

            Text("\(stability.periodsWithinTolerance) of \(stability.totalClosedPeriods) periods within range")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Period dots
            HStack(spacing: PPSpacing.sm) {
                ForEach(stability.recentClosedPeriods.indices, id: \.self) { index in
                    let period = stability.recentClosedPeriods[index]
                    Circle()
                        .fill(period.isOutsideTolerance ? Color.ppTextTertiary : Color.ppPrimary)
                        .frame(width: 10, height: 10)
                }
            }

            let outsideCount = stability.recentClosedPeriods.filter { $0.isOutsideTolerance }.count
            let total = stability.recentClosedPeriods.count
            Text("\(outsideCount) of the last \(total) closed periods were outside tolerance.")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Net Position Card

    private func netPositionCard(net: NetPosition) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("NET POSITION")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(net.totalNetPosition, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppCyan)

            HStack(spacing: PPSpacing.sm) {
                let changePrefix = net.changeThisPeriod >= 0 ? "+" : ""
                Text("\(changePrefix)\(formatCurrency(net.changeThisPeriod, code: appState.currencyCode)) this period")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)

                Text("·")
                    .foregroundColor(.ppTextTertiary)

                Text("Across \(net.accountCount) accounts")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
            }

            // Balance breakdown bar
            if net.totalNetPosition != 0 {
                let total = abs(net.liquidBalance) + abs(net.protectedBalance) + abs(net.debtBalance)
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if net.liquidBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppCyan)
                                .frame(width: geo.size.width * barFraction(abs(net.liquidBalance), of: total))
                        }
                        if net.protectedBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppPrimary)
                                .frame(width: geo.size.width * barFraction(abs(net.protectedBalance), of: total))
                        }
                        if net.debtBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppAmber)
                                .frame(width: geo.size.width * barFraction(abs(net.debtBalance), of: total))
                        }
                    }
                }
                .frame(height: 6)
            }

            // Breakdown text
            Text("Liquid \(formatCurrency(net.liquidBalance, code: appState.currencyCode)) · Protected \(formatCurrency(net.protectedBalance, code: appState.currencyCode)) · Debt \(formatCurrency(net.debtBalance, code: appState.currencyCode))")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers
    
    private func projectedSpendAmount(burnIn: MonthlyBurnIn, progress: MonthProgress) -> Int64 {
        let daysPassed = progress.daysInPeriod - progress.remainingDays
        guard daysPassed > 0 else { return 0 }
        let dailyRate = Double(burnIn.spentBudget) / Double(daysPassed)
        return Int64(dailyRate * Double(progress.daysInPeriod))
    }

    private func barFraction(_ value: Int64, of total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
}
