import SwiftUI

struct BudgetPlanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: BudgetViewModel

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: BudgetViewModel(apiClient: apiClient))
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text("Budget Plan")
                        .font(.ppLargeTitle)
                        .foregroundColor(.ppPrimary)

                    Text("Manage your spending limits and assign budgets to your categories.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }
                .listRowBackground(Color.ppBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.lg, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
            }

            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView().tint(.ppTextSecondary)
                        Spacer()
                    }
                    .padding(.vertical, PPSpacing.xxxl)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    VStack(spacing: PPSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.ppAmber)
                        Text(error)
                            .font(.ppBody)
                            .foregroundColor(.ppTextSecondary)
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
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                }
            } else {
                // Budget Summary card
                if let burnIn = viewModel.burnIn {
                    Section {
                        summaryCard(burnIn: burnIn)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                }

                // Budgeted Categories
                Section {
                    if viewModel.categories.isEmpty {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 32))
                                .foregroundColor(.ppTextTertiary)
                            Text("No budget categories yet")
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Text("Assign budgets to your categories from the web app to see them here.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.categories) { cat in
                            categoryRow(cat)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }
                    }
                } header: {
                    if !viewModel.categories.isEmpty {
                        Text("BUDGETED CATEGORIES")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
    }

    // MARK: - Summary Card

    private func summaryCard(burnIn: MonthlyBurnIn) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("BUDGET BREAKDOWN")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            VStack(spacing: PPSpacing.md) {
                breakdownRow("Total Budget", value: burnIn.totalBudget, color: .ppPrimary)
                breakdownRow("Currently Spent", value: burnIn.spentBudget, color: .ppTextSecondary)
                breakdownRow("Remaining Budget", value: burnIn.remainingBudget, color: .ppCyan)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(burnIn.spentPercentage > 1.0 ? Color.ppDestructive : Color.ppPrimary)
                        .frame(width: geo.size.width * min(burnIn.spentPercentage, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    private func breakdownRow(_ label: String, value: Int64, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)
            Spacer()
            Text(formatCurrency(value))
                .font(.ppCallout)
                .fontWeight(.semibold)
                .foregroundColor(.ppTextPrimary)
        }
    }

    // MARK: - Category Row

    private func categoryRow(_ item: BudgetCategoryItem) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            HStack {
                Text(item.category.icon)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.category.name)
                        .font(.ppHeadline)
                        .foregroundColor(.ppTextPrimary)

                    Text("Budget: \(formatCurrency(Int64(item.budgetedValue)))")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }

                Spacer()
            }

            // Progress bar placeholder (we don't have per-category spend from this endpoint)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: item.category.color) ?? .ppPrimary)
                    .frame(height: 4)
            }
            .frame(height: 4)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.md)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func formatCurrency(_ cents: Int64) -> String {
        let value = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}
