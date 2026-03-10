import SwiftUI

struct PeriodsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: PeriodsViewModel
    @State private var showCreateSheet = false
    @State private var periodToDelete: BudgetPeriod?

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: PeriodsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PPSpacing.xl) {
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
                                .foregroundColor(.ppAmber)
                            Text(error)
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Button("Retry") {
                                Task { await viewModel.load() }
                            }
                            .font(.ppHeadline)
                            .foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                    } else {
                        scheduleSection
                        currentPeriodSection
                        upcomingSection
                        pastSection
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                Task { await viewModel.load() }
            }) {
                CreatePeriodSheet { }
                    .environmentObject(appState)
            }
            .confirmationDialog(
                "Delete this period?",
                isPresented: Binding(
                    get: { periodToDelete != nil },
                    set: { if !$0 { periodToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let p = periodToDelete {
                        Task { await deletePeriod(p) }
                    }
                    periodToDelete = nil
                }
                Button("Cancel", role: .cancel) { periodToDelete = nil }
            } message: {
                Text("This will permanently remove the period.")
            }
            .navigationTitle("Periods")
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
            sectionHeader("SCHEDULE")
            NavigationLink {
                AutoCreationView()
                    .environmentObject(appState)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Creation")
                            .font(.ppHeadline)
                            .foregroundColor(.ppTextPrimary)
                        Text("Automatic period generation")
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                    Spacer()
                    Text(viewModel.hasSchedule ? "Enabled" : "Not set up")
                        .font(.ppCaption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.hasSchedule ? .ppCyan : .ppAmber)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 4)
                        .background((viewModel.hasSchedule ? Color.ppCyan : Color.ppAmber).opacity(0.12))
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

    // MARK: - Current Period

    private var currentPeriodSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            sectionHeader("CURRENT PERIOD")
            if let period = viewModel.currentPeriod {
                NavigationLink {
                    PeriodDetailView(period: period)
                        .environmentObject(appState)
                } label: {
                    periodCard(period, highlight: true)
                }
                .buttonStyle(.plain)
            } else {
                Text("No active period.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PPSpacing.lg)
                    .background(Color.ppCard)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack {
                sectionHeader("UPCOMING PERIODS")
                Spacer()
                countBadge(viewModel.upcomingPeriods.count)
            }
            if viewModel.upcomingPeriods.isEmpty {
                Text("No upcoming periods.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                ForEach(viewModel.upcomingPeriods) { period in
                    NavigationLink {
                        PeriodDetailView(period: period)
                            .environmentObject(appState)
                    } label: {
                        periodCard(period, highlight: false)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            periodToDelete = period
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Past

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            DisclosureGroup(
                isExpanded: $viewModel.showPastPeriods,
                content: {
                    VStack(spacing: PPSpacing.sm) {
                        ForEach(viewModel.pastPeriods) { period in
                            NavigationLink {
                                PeriodDetailView(period: period)
                                    .environmentObject(appState)
                            } label: {
                                periodCard(period, highlight: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, PPSpacing.sm)
                },
                label: {
                    HStack {
                        sectionHeader("PAST PERIODS")
                        Spacer()
                        countBadge(viewModel.pastPeriods.count)
                    }
                }
            )
            .tint(.ppTextSecondary)
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
                            .foregroundColor(statusColor(period.status))
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
                Label("\(period.transactionCount) transactions", systemImage: "arrow.left.arrow.right")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)

                Spacer()

                if period.budgetUsedPercentage > 0 {
                    Text("\(Int(period.budgetUsedPercentage))% used")
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
                .stroke(highlight ? Color.ppPrimary.opacity(0.5) : Color.ppBorder, lineWidth: highlight ? 1.5 : 1)
        )
        .shadow(color: highlight ? Color.ppPrimary.opacity(0.15) : .clear, radius: 8, x: 0, y: 0)
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
        case .active: return .ppCyan
        case .ended: return .ppTextTertiary
        case .upcoming: return .ppAmber
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
