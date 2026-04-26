import SwiftUI
import TipKit

struct PeriodsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = PeriodsViewModel()
    @State private var showCreateSheet = false
    @State private var periodToDelete: BudgetPeriod?

    private let periodsTip = PeriodsTip()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PPSpacing.xl) {
                    TipView(periodsTip)

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView().tint(.ppTextSecondary)
                            Spacer()
                        }
                        .padding(.vertical, PPSpacing.xxxl)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(theme.secondary)
                            Text(error)
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Button(String(localized: "common.retry")) {
                                Task { await viewModel.load() }
                            }
                            .font(.ppHeadline)
                            .foregroundColor(theme.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                    } else if periodsByYear.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            title: String(localized: "periods.empty.title"),
                            message: String(localized: "periods.empty.message"),
                            steps: [
                                EmptyStateStep(
                                    title: String(localized: "periods.empty.step1.title"),
                                    description: String(localized: "periods.empty.step1.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "periods.empty.step2.title"),
                                    description: String(localized: "periods.empty.step2.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "periods.empty.step3.title"),
                                    description: String(localized: "periods.empty.step3.description")
                                ),
                            ],
                            tips: [
                                String(localized: "periods.empty.tip1"),
                                String(localized: "periods.empty.tip2"),
                                String(localized: "periods.empty.tip3"),
                            ],
                            actionLabel: String(localized: "periods.empty.action"),
                            action: { showCreateSheet = true }
                        )
                    } else {
                        // Schedule status pill
                        scheduleStatusPill

                        scheduleSection

                        // Group by year
                        ForEach(periodsByYear, id: \.year) { group in
                            yearSection(group)
                        }
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .refreshable { await viewModel.load() }
            .task {
                viewModel.configure(apiClient: appState.apiClient, dataStore: appState.dataStore)
                await viewModel.load()
            }
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                Task { await viewModel.load() }
            }) {
                CreatePeriodSheet { }
                    .environmentObject(appState)
            }
            .confirmationDialog(
                String(localized: "periods.deleteConfirm"),
                isPresented: Binding(
                    get: { periodToDelete != nil },
                    set: { if !$0 { periodToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(String(localized: "common.delete"), role: .destructive) {
                    if let p = periodToDelete {
                        Task { await deletePeriod(p) }
                    }
                    periodToDelete = nil
                }
                Button(String(localized: "common.cancel"), role: .cancel) { periodToDelete = nil }
            } message: {
                Text(String(localized: "periods.deleteMessage"))
            }
            .navigationTitle(String(localized: "nav.periods"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateSheet = true } label: { Image(systemName: "plus") }
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            sectionHeader(String(localized: "section.schedule"))
            NavigationLink {
                AutoCreationView()
                    .environmentObject(appState)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "periods.autoCreation"))
                            .font(.ppHeadline)
                            .foregroundColor(.ppTextPrimary)
                        Text(String(localized: "periods.autoCreationDesc"))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                    Spacer()
                    Text(viewModel.hasSchedule ? String(localized: "periods.enabled") : String(localized: "periods.notSetUp"))
                        .font(.ppCaption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.hasSchedule ? theme.tertiary : theme.secondary)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 4)
                        .background((viewModel.hasSchedule ? theme.tertiary : theme.secondary).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ppTextTertiary)
                }
                .padding(PPSpacing.lg)
                .background(Color.ppCard)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Schedule Status Pill

    private var scheduleStatusPill: some View {
        HStack(spacing: PPSpacing.sm) {
            Circle()
                .fill(viewModel.hasSchedule ? theme.tertiary : theme.secondary)
                .frame(width: 8, height: 8)
            Text(viewModel.hasSchedule ? String(localized: "periods.autoGeneration.active") : String(localized: "periods.autoGeneration.inactive"))
                .font(.ppCaption)
                .fontWeight(.medium)
                .foregroundColor(viewModel.hasSchedule ? theme.tertiary : theme.secondary)
        }
        .padding(.horizontal, PPSpacing.md)
        .padding(.vertical, PPSpacing.sm)
        .background((viewModel.hasSchedule ? theme.tertiary : theme.secondary).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
    }

    // MARK: - Year-grouped periods

    private struct YearGroup: Hashable {
        let year: Int
        let periods: [BudgetPeriod]

        func hash(into hasher: inout Hasher) { hasher.combine(year) }
        static func == (lhs: YearGroup, rhs: YearGroup) -> Bool { lhs.year == rhs.year }
    }

    private var periodsByYear: [YearGroup] {
        var allPeriods: [BudgetPeriod] = []
        if let current = viewModel.currentPeriod { allPeriods.append(current) }
        allPeriods.append(contentsOf: viewModel.upcomingPeriods)
        allPeriods.append(contentsOf: viewModel.pastPeriods)

        let grouped = Dictionary(grouping: allPeriods) { period -> Int in
            guard let date = period.startDateFormatted else { return 0 }
            return Calendar.current.component(.year, from: date)
        }

        return grouped.keys.sorted(by: >).map { year in
            YearGroup(year: year, periods: grouped[year]!.sorted { ($0.startDate) > ($1.startDate) })
        }
    }

    private func yearSection(_ group: YearGroup) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack {
                sectionHeader("\(group.year)")
                Spacer()
                countBadge(group.periods.count)
            }

            ForEach(group.periods) { period in
                NavigationLink {
                    PeriodDetailView(period: period)
                        .environmentObject(appState)
                } label: {
                    periodCard(period, highlight: period.periodStatus == .active)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        periodToDelete = period
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Period Card

    private func periodCard(_ period: BudgetPeriod, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
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

                if period.isAutoGenerated {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.ppTextTertiary)
                }
            }

            HStack {
                Label(String(localized: "periods.transactionCount \(period.transactionCount)"), systemImage: "arrow.left.arrow.right")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)

                Spacer()

                if period.budgetUsedPercentage > 0 {
                    Text(String(localized: "periods.budgetUsed \(Int(period.budgetUsedPercentage))"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(highlight ? theme.primary.opacity(0.5) : Color.ppBorder, lineWidth: highlight ? 1.5 : 1)
        )
        .shadow(color: highlight ? theme.primary.opacity(0.15) : .clear, radius: 8, x: 0, y: 0)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.ppOverline)
            .foregroundColor(.ppTextSecondary)
            .tracking(1)
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.ppCaption)
            .foregroundColor(.ppTextSecondary)
            .padding(.horizontal, PPSpacing.sm)
            .padding(.vertical, 2)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return theme.tertiary
        case .ended: return .ppTextTertiary
        case .upcoming: return theme.secondary
        case .unknown: return .ppTextTertiary
        }
    }

    private func deletePeriod(_ period: BudgetPeriod) async {
        do {
            try await appState.apiClient.requestVoid(.deletePeriod(period.id))
            await viewModel.load()
        } catch {
            viewModel.errorMessage = String(localized: "Failed to delete period.")
        }
    }
}
