import SwiftUI

struct PeriodsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: PeriodsViewModel
    @State private var showCreateSheet = false

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: PeriodsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            List {
                // Header
                Section {
                    VStack(alignment: .leading, spacing: PPSpacing.xs) {
                        Text("Periods")
                            .font(.ppLargeTitle)
                            .foregroundColor(.ppPrimary)
                        
                        Text("Time windows that help you track patterns")
                            .font(.ppCallout)
                            .foregroundColor(.ppTextSecondary)
                    }
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: PPSpacing.lg, leading: PPSpacing.lg, bottom: PPSpacing.sm, trailing: PPSpacing.lg))
                    
                    // Create button
                    Button {
                        showCreateSheet = true
                    } label: {
                        Text("Create Period")
                            .font(.ppHeadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PPSpacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.ppPrimary)
                    .cornerRadius(PPRadius.full)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
                }
                
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
                                    .foregroundColor(.ppTextPrimary)
                                Text("Configure automatic period generation")
                                    .font(.ppCaption)
                                    .foregroundColor(.ppTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(PPSpacing.lg)
                        .background(Color.ppCard)
                        .cornerRadius(PPRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                } header: {
                    Text("SCHEDULE")
                        .font(.ppOverline)
                        .foregroundColor(.ppTextSecondary)
                        .tracking(1)
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
                                Task { await viewModel.load() }
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
            .background(Color.ppBackground)
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
                .listRowBackground(Color.ppBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
            } else {
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("No current period found.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PPSpacing.xl)
                .background(Color.ppCard)
                .cornerRadius(PPRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: PPRadius.lg)
                        .stroke(Color.ppPrimary.opacity(0.3), lineWidth: 1)
                )
                .listRowBackground(Color.ppBackground)
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
                    .foregroundColor(.ppTextTertiary)
                    .padding(.vertical, PPSpacing.md)
                    .listRowBackground(Color.ppBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: PPSpacing.lg, bottom: 0, trailing: PPSpacing.lg))
            } else {
                ForEach(viewModel.upcomingPeriods) { period in
                    NavigationLink {
                        PeriodDetailView(period: period)
                            .environmentObject(appState)
                    } label: {
                        periodCard(period, highlight: true)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.ppBackground)
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
                    .foregroundColor(.ppTextSecondary)
                    .padding(.horizontal, PPSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.ppCard)
                    .cornerRadius(PPRadius.full)
            }
        }
    }

    // MARK: - Past

    private var pastSection: some View {
        Section {
            if viewModel.pastPeriods.isEmpty {
                Text("No past periods.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
                    .padding(.vertical, PPSpacing.md)
                    .listRowBackground(Color.ppBackground)
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
                    .listRowBackground(Color.ppBackground)
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
                        .foregroundColor(.ppTextSecondary)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.ppCard)
                        .cornerRadius(PPRadius.full)
                    Image(systemName: viewModel.showPastPeriods ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.ppTextSecondary)
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
        .cornerRadius(PPRadius.lg)
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

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return .ppCyan
        case .ended: return .ppTextTertiary
        case .upcoming: return .ppAmber
        case .unknown: return .ppTextTertiary
        }
    }
}
