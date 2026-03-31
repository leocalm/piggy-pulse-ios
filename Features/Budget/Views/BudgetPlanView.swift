import SwiftUI

struct BudgetPlanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = BudgetViewModel()
    @State private var selectedTarget: CategoryTarget?

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "more.targets"), showTitle: false)
            } else {
                List {
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
                                Button(String(localized: "common.retry")) {
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
                        let withTarget = viewModel.targets.filter { !$0.isExcluded && ($0.currentTarget ?? 0) > 0 }
                        let excluded = viewModel.targets.filter { $0.isExcluded }
                        let noTarget = viewModel.targets.filter { !$0.isExcluded && ($0.currentTarget ?? 0) == 0 }

                        // Stats bar
                        Section {
                            budgetStatsBar(withTarget: withTarget, noTarget: noTarget, excluded: excluded)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }

                        // Budget Summary card (computed from non-excluded targets only)
                        if viewModel.burnIn != nil {
                            Section {
                                summaryCard(withTarget: withTarget)
                                    .listRowBackground(Color.ppBackground)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                            }
                        }

                        if !withTarget.isEmpty {
                            Section {
                                ForEach(withTarget) { target in
                                    targetRow(target)
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                        .swipeActions(edge: .trailing) {
                                            Button {
                                                if let periodId = appState.selectedPeriod?.id {
                                                    Task { await viewModel.excludeTarget(id: target.id, periodId: periodId) }
                                                }
                                            } label: {
                                                Label(String(localized: "button.exclude"), systemImage: "eye.slash")
                                            }
                                            .tint(.ppAmber)
                                        }
                                        .onTapGesture { selectedTarget = target }
                                }
                            } header: {
                                Text(String(localized: "budget.withTarget"))
                                    .font(.ppOverline)
                                    .foregroundColor(.ppTextSecondary)
                                    .tracking(1)
                            }
                        }

                        if !noTarget.isEmpty {
                            Section {
                                ForEach(noTarget) { target in
                                    noTargetRow(target)
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                        .onTapGesture { selectedTarget = target }
                                }
                            } header: {
                                Text(String(localized: "budget.noTarget"))
                                    .font(.ppOverline)
                                    .foregroundColor(.ppTextSecondary)
                                    .tracking(1)
                            }
                        }

                        if !excluded.isEmpty {
                            Section {
                                ForEach(excluded) { target in
                                    excludedRow(target)
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                        .swipeActions(edge: .trailing) {
                                            Button {
                                                if let periodId = appState.selectedPeriod?.id {
                                                    Task { await viewModel.includeTarget(id: target.id, periodId: periodId) }
                                                }
                                            } label: {
                                                Label(String(localized: "button.include"), systemImage: "eye")
                                            }
                                            .tint(.ppCyan)
                                        }
                                        .onTapGesture { selectedTarget = target }
                                }
                            } header: {
                                Text(String(localized: "budget.excluded"))
                                    .font(.ppOverline)
                                    .foregroundColor(.ppTextSecondary)
                                    .tracking(1)
                            }
                        }

                        if viewModel.targets.isEmpty {
                            Section {
                                VStack(spacing: PPSpacing.md) {
                                    Image(systemName: "chart.pie")
                                        .font(.system(size: 32))
                                        .foregroundColor(.ppTextTertiary)
                                    Text(String(localized: "budget.noCategories"))
                                        .font(.ppBody)
                                        .foregroundColor(.ppTextSecondary)
                                    Text(String(localized: "budget.noCategoriesHint"))
                                        .font(.ppCallout)
                                        .foregroundColor(.ppTextTertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PPSpacing.xl)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
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
                    viewModel.configure(apiClient: appState.apiClient)
                    if let periodId = appState.selectedPeriod?.id {
                        await viewModel.load(periodId: periodId)
                    }
                }
                .navigationTitle(String(localized: "more.targets"))
                .navigationBarTitleDisplayMode(.large)
                .sheet(item: $selectedTarget) { target in
                    EditCategoryTargetSheet(
                        target: target,
                        onSave: { cents in
                            if let periodId = appState.selectedPeriod?.id {
                                await viewModel.setTarget(categoryId: target.categoryId, value: cents, periodId: periodId)
                            }
                        },
                        onExclude: {
                            if let periodId = appState.selectedPeriod?.id {
                                await viewModel.excludeTarget(id: target.id, periodId: periodId)
                            }
                        },
                        onInclude: {
                            if let periodId = appState.selectedPeriod?.id {
                                await viewModel.includeTarget(id: target.id, periodId: periodId)
                            }
                        }
                    )
                    .environmentObject(appState)
                }
            } // else
        } // NavigationStack
    }

    // MARK: - Stats Bar

    private func budgetStatsBar(withTarget: [CategoryTarget], noTarget: [CategoryTarget], excluded: [CategoryTarget]) -> some View {
        let periodName = appState.selectedPeriod?.name ?? ""
        let expenseTargets = withTarget.filter { $0.categoryType == "outgoing" }
        let incomeTargets = withTarget.filter { $0.categoryType == "incoming" }
        let expenseBudget = expenseTargets.reduce(Int64(0)) { $0 + Int64($1.currentTarget ?? 0) }
        let incomeTarget = incomeTargets.reduce(Int64(0)) { $0 + Int64($1.currentTarget ?? 0) }
        let totalCategories = withTarget.count + noTarget.count + excluded.count
        let withTargetCount = withTarget.count

        return VStack(alignment: .leading, spacing: PPSpacing.md) {
            if !periodName.isEmpty {
                Text(periodName)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
            }

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(formatCurrency(expenseBudget, code: appState.currencyCode))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(localized: "budget.stats.expenseBudget"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Text(formatCurrency(incomeTarget, code: appState.currencyCode))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(localized: "budget.stats.incomeTarget"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Text("\(withTargetCount)/\(totalCategories)")
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                    Text(String(localized: "budget.stats.withTargets"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    // MARK: - Summary Card

    private func summaryCard(withTarget: [CategoryTarget]) -> some View {
        let totalBudget = withTarget.reduce(0) { $0 + Int64($1.currentTarget ?? 0) }
        let spentBudget = withTarget.reduce(0) { $0 + ($1.spentAmount ?? 0) }
        let remainingBudget = totalBudget - spentBudget
        let spentPercentage = totalBudget > 0 ? Double(spentBudget) / Double(totalBudget) : 0.0

        return VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "budget.breakdown"))
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            VStack(spacing: PPSpacing.md) {
                breakdownRow(String(localized: "budget.totalBudget"), value: totalBudget, color: .ppPrimary)
                breakdownRow(String(localized: "budget.currentlySpent"), value: spentBudget, color: .ppTextSecondary)
                breakdownRow(String(localized: "budget.remainingBudget"), value: remainingBudget, color: .ppCyan)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppPrimary)
                        .frame(width: geo.size.width * min(spentPercentage, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func breakdownRow(_ label: String, value: Int64, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(formatCurrency(value, code: appState.currencyCode))
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
        }
    }

    // MARK: - Category Rows

    private func targetRow(_ target: CategoryTarget) -> some View {
        return HStack(spacing: PPSpacing.md) {
            Text(target.categoryIcon)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(target.categoryName)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                Text(formatCurrency(target.spentAmount ?? 0, code: appState.currencyCode))
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "budget.ofTarget \(formatCurrency(Int64(target.currentTarget ?? 0), code: appState.currencyCode))"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func noTargetRow(_ target: CategoryTarget) -> some View {
        return HStack(spacing: PPSpacing.md) {
            Text(target.categoryIcon)
                .font(.system(size: 20))
                .opacity(0.5)
            Text(target.categoryName)
                .font(.ppHeadline)
                .foregroundColor(.ppTextTertiary)
            Spacer()
            Text(String(localized: "budget.noTargetLabel"))
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
            Image(systemName: "plus.circle")
                .font(.ppCallout)
                .foregroundColor(.ppPrimary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder.opacity(0.5), lineWidth: 1))
    }

    private func excludedRow(_ target: CategoryTarget) -> some View {
        return HStack(spacing: PPSpacing.md) {
            Text(target.categoryIcon)
                .font(.system(size: 20))
                .grayscale(1)
                .opacity(0.4)
            Text(target.categoryName)
                .font(.ppHeadline)
                .foregroundColor(.ppTextTertiary)
                .strikethrough(true, color: .ppTextTertiary)
            Spacer()
            Text(String(localized: "budget.excludedLabel"))
                .font(.ppCaption)
                .foregroundColor(.ppAmber)
                .padding(.horizontal, PPSpacing.sm)
                .padding(.vertical, 2)
                .background(Color.ppAmber.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder.opacity(0.3), lineWidth: 1))
    }
}
