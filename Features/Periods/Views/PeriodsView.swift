import SwiftUI

struct PeriodsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: PeriodsViewModel
    @State private var showCreateSheet = false

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: PeriodsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            List {
               // Schedule section
                Section {
                    NavigationLink {
                        AutoCreationView()
                            .environmentObject(appState)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-Creation")
                                    .font(.ppHeadline)
                                    .foregroundColor(.ppTextPrimary(colorScheme))
                                Text("Configure automatic period generation")
                                    .font(.ppCaption)
                                    .foregroundColor(.ppTextSecondary(colorScheme))
                            }
                            Spacer()
                        }
                        .padding(PPSpacing.lg)
                        .background(Color.ppCard(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.ppBackground(colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                } header: {
                    Text("SCHEDULE")
                        .font(.ppOverline)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                        .tracking(1)
                }

                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView().tint(.ppTextSecondary(colorScheme))
                            Spacer()
                        }
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground(colorScheme))
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
                                .foregroundColor(.ppTextSecondary(colorScheme))
                            Button("Retry") {
                                Task { await viewModel.load() }
                            }
                            .font(.ppHeadline)
                            .foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground(colorScheme))
                        .listRowSeparator(.hidden)
                    }
                } else {
                    // Current Period
                    currentPeriodSection

                    // Upcoming Periods
                    upcomingSection

                    // Past Periods
                    pastSection
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground(colorScheme))
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                Task { await viewModel.load() }
            }) {
                CreatePeriodSheet {
                    // No need to reload here, onDismiss handles it
                }
                .environmentObject(appState)
            }
            .navigationTitle("Periods")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.white)
                }
            }
        }
    }

    // MARK: - Current Period

    private var currentPeriodSection: some View {
        Section {
            if let period = viewModel.currentPeriod {
                NavigationLink {
                    PeriodDetailView(period: period)
                        .environmentObject(appState)
                } label: {
                    periodCard(period, highlight: true)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.ppBackground(colorScheme))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
            } else {
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("No current period found.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PPSpacing.xl)
                .background(Color.ppCard(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: PPRadius.lg)
                        .stroke(Color.ppPrimary.opacity(0.3), lineWidth: 1)
                )
                .listRowBackground(Color.ppBackground(colorScheme))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
            }
        } header: {
            sectionHeader("CURRENT PERIOD")
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        Section {
            if viewModel.upcomingPeriods.isEmpty {
                Text("No upcoming periods.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary(colorScheme))
                    .padding(.vertical, PPSpacing.md)
                    .listRowBackground(Color.ppBackground(colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: PPSpacing.lg, bottom: 0, trailing: PPSpacing.lg))
            } else {
                ForEach(viewModel.upcomingPeriods) { period in
                    NavigationLink {
                        PeriodDetailView(period: period)
                    } label: {
                        periodCard(period, highlight: false)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await deletePeriod(period) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.ppBackground(colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                }
            }
        } header: {
            HStack {
                sectionHeader("UPCOMING PERIODS")
                Spacer()
                Text("\(viewModel.upcomingPeriods.count)")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary(colorScheme))
                    .padding(.horizontal, PPSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.ppCard(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
            }
        }
    }

    private func deletePeriod(_ period: BudgetPeriod) async {
        do {
            try await appState.apiClient.requestVoid(.deletePeriod(period.id))
            await viewModel.load()
        } catch {}
    }

    // MARK: - Past

    private var pastSection: some View {
        Section {
            if viewModel.pastPeriods.isEmpty {
                Text("No past periods.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary(colorScheme))
                    .padding(.vertical, PPSpacing.md)
                    .listRowBackground(Color.ppBackground(colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: PPSpacing.lg, bottom: 0, trailing: PPSpacing.lg))
            } else if viewModel.showPastPeriods {
                ForEach(viewModel.pastPeriods) { period in
                    NavigationLink {
                        PeriodDetailView(period: period)
                            .environmentObject(appState)
                    } label: {
                        periodCard(period, highlight: true)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.ppBackground(colorScheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                }
            }
        } header: {
            Button {
                withAnimation { viewModel.showPastPeriods.toggle() }
            } label: {
                HStack {
                    sectionHeader("PAST PERIODS")
                    Spacer()
                    Text("\(viewModel.pastPeriods.count)")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.ppCard(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                    Image(systemName: viewModel.showPastPeriods ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.ppTextSecondary(colorScheme))
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
                        .foregroundColor(.ppTextPrimary(colorScheme))

                    HStack(spacing: 4) {
                        Text(period.dateRangeText)
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary(colorScheme))
                        Text("·")
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary(colorScheme))
                        Text(period.statusText)
                            .font(.ppCaption)
                            .foregroundColor(statusColor(period.status))
                    }
                }

                Spacer()

                if period.isAutoGenerated {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.ppTextTertiary(colorScheme))
                }
            }

            HStack {
                Label("\(period.transactionCount) transactions", systemImage: "arrow.left.arrow.right")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary(colorScheme))

                Spacer()

                if period.budgetUsedPercentage > 0 {
                    Text("\(Int(period.budgetUsedPercentage))% used")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(highlight ? Color.ppPrimary.opacity(0.5) : Color.ppBorder(colorScheme), lineWidth: highlight ? 1.5 : 1)
        )
        .shadow(color: highlight ? Color.ppPrimary.opacity(0.15) : .clear, radius: 8, x: 0, y: 0)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.ppOverline)
            .foregroundColor(.ppTextSecondary(colorScheme))
            .tracking(1)
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return .ppCyan
        case .ended: return .ppTextTertiary(colorScheme)
        case .upcoming: return .ppAmber
        case .unknown: return .ppTextTertiary(colorScheme)
        }
    }
}
